defmodule Songy.Providers do
  @moduledoc """
  Provider data storage with ETS.

  Stores provider credentials and metadata in memory with automatic token refresh.
  User-centric storage structure: user_id -> provider_data.
  Each user can have only one active provider at a time.
  """

  use GenServer

  require Logger

  ## Client API

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
  Inserts or updates provider data for a specific user.

  ## Examples
      iex> {:ok, pid} = Songy.Providers.start_link()
      iex> spotify_data = %Songy.Core.Provider.Spotify{access_token: "token"}
      iex> Songy.Providers.insert(pid, "user123", spotify_data)
      :ok

      iex> Songy.Providers.insert(:providers, "user123", spotify_data)
      :ok
  """
  @spec insert(GenServer.server(), String.t(), term()) :: :ok
  def insert(server, user_id, data)
      when (is_pid(server) or is_atom(server)) and is_binary(user_id) do
    GenServer.call(server, {:insert, user_id, data})
  end

  @doc """
  Updates provider data for a specific user.

  ## Examples
      iex> new_data = %Songy.Core.Provider.Spotify{access_token: "token1", device_id: "device1"}
      iex> Songy.Providers.update(:providers, "user123", new_data)
      :ok
  """
  @spec update(GenServer.server(), String.t(), term()) :: :ok
  def update(server, user_id, attrs)
      when (is_pid(server) or is_atom(server)) and is_binary(user_id) do
    GenServer.call(server, {:update, user_id, attrs})
  end

  @doc """
  Looks up the provider data for user. Automatically refreshes tokens if they're close to expiry.

  ## Examples
      iex> {:ok, pid} = Songy.Providers.start_link(name: :providers)
      iex> Songy.Providers.lookup(:providers, "user123")
      {:ok, %Songy.Core.Provider.Spotify{access_token: "fresh_token", refresh_token: "refresh"}}

      iex> Songy.Providers.lookup(:providers, "unknown_user")
      {:error, :not_found}
  """
  @spec lookup(term(), String.t()) :: {:ok, term()} | {:error, atom()}
  def lookup(registry, user_id) when is_binary(user_id) do
    with [{^user_id, data}] <- :ets.lookup(registry, user_id),
         {:ok, updated_data} <- Songy.Boundary.Provider.ensure(data),
         {:match, true, _} <- {:match, match?(^data, updated_data), updated_data} do
      {:ok, data}
    else
      {:match, false, updated_data} ->
        GenServer.call(registry, {:update, user_id, updated_data})
        {:ok, updated_data}

      [] ->
        {:error, :not_found}

      {:error, reason} ->
        GenServer.call(registry, {:remove, user_id})
        {:error, reason}
    end
  end

  @impl true
  def init(table) do
    credentials = :ets.new(table, [:named_table, :set, :protected, read_concurrency: true])

    {:ok, credentials}
  end

  @impl true
  def handle_call({:insert, user_id, data}, _from, table) do
    :ets.insert(table, {user_id, data})
    Logger.debug("Inserted provider data for user #{user_id}")

    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:update, user_id, data}, _from, table) do
    :ets.insert(table, {user_id, data})
    Logger.debug("Updated provider data for user #{user_id}")
    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:remove, user_id}, _from, table) do
    :ets.delete(table, user_id)
    Logger.info("Removed provider data for user #{user_id}")
    {:reply, :ok, table}
  end

  @impl true
  def handle_info(_msg, table) do
    {:noreply, table}
  end
end
