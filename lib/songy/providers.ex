defmodule Songy.Providers do
  @moduledoc """
  Provider data storage with ETS.

  Stores provider credentials and metadata in memory with automatic token refresh.
  User-centric storage structure: {user_uuid, provider} keys.
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
  Merges with existing data if present.

  ## Examples
      iex> {:ok, pid} = Songy.Providers.start_link()
      iex> Songy.Providers.insert(pid, "user123", :spotify, %{access_token: "token"})
      :ok

      iex> Songy.Providers.insert(:providers, "user123", :spotify, %{access_token: "token"})
      :ok
  """
  @spec insert(GenServer.server(), String.t(), atom(), map()) :: :ok
  def insert(server, user_uuid, provider, attrs \\ %{})
      when (is_pid(server) or is_atom(server)) and is_binary(user_uuid) and is_atom(provider) and is_map(attrs) do
    GenServer.call(server, {:insert, user_uuid, provider, attrs})
  end

  @doc """
  Looks up the provider data for user.
  Automatically refreshes tokens if they're close to expiry.

  ## Examples
      iex> {:ok, pid} = Songy.Providers.start_link(name: :providers)
      iex> Songy.Providers.lookup(:providers, "user123", :spotify)
      {:ok, %{access_token: "fresh_token", refresh_token: "refresh"}}

      iex> Songy.Providers.lookup(:providers, "user123", :unknown)
      {:error, :not_found}
  """
  @spec lookup(term(), String.t(), atom()) :: {:ok, map()} | {:error, atom()}
  def lookup(registry, user_uuid, provider) when is_binary(user_uuid) and is_atom(provider) do
    key = {user_uuid, provider}

    with [{^key, data}] <- :ets.lookup(registry, key),
         {:ok, ensured_data} <- ensure_data(provider, data),
         {:match, true, _} <- {:match, match?(^data, ensured_data), ensured_data} do
      {:ok, data}
    else
      {:match, false, data} ->
        GenServer.call(registry, {:update, user_uuid, provider, data})
        {:ok, data}

      [] ->
        {:error, :not_found}

      {:error, reason} ->
        GenServer.call(registry, {:remove, user_uuid, provider})
        {:error, reason}
    end
  end

  @impl true
  def init(table) do
    credentials = :ets.new(table, [:named_table, :set, :protected, read_concurrency: true])

    {:ok, credentials}
  end

  @impl true
  def handle_call({:insert, user_uuid, provider, attrs}, _from, table) do
    key = {user_uuid, provider}

    data =
      case :ets.lookup(table, key) do
        [{^key, existing}] -> Map.merge(existing, attrs)
        [] -> attrs
      end

    :ets.insert(table, {key, data})
    Logger.debug("Inserted #{provider} data for user #{user_uuid}")
    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:update, user_uuid, provider, data}, _from, table) do
    key = {user_uuid, provider}
    :ets.insert(table, {key, data})
    Logger.debug("Updated #{provider} data for user #{user_uuid}")
    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:remove, user_uuid, provider}, _from, table) do
    key = {user_uuid, provider}
    :ets.delete(table, key)
    Logger.info("Removed #{provider} data for user #{user_uuid}")
    {:reply, :ok, table}
  end

  @impl true
  def handle_info(_msg, table) do
    {:noreply, table}
  end

  defp ensure_data(:spotify, data) do
    Songy.Boundary.Spotify.ensure_fresh_credentials(data)
  end

  defp ensure_data(_provider, data) do
    {:ok, data}
  end
end
