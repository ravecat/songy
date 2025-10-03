defmodule Songy.Providers do
  @moduledoc """
  Provider data storage with ETS.

  Stores provider credentials and metadata in memory with automatic token refresh.
  User-centric storage structure: user_id -> {provider, provider_data}.
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
      iex> Songy.Providers.insert(pid, "user123", :spotify, %{access_token: "token"})
      :ok

      iex> Songy.Providers.insert(:providers, "user123", :spotify, %{access_token: "token"})
      :ok
  """
  @spec insert(GenServer.server(), String.t(), atom(), map()) :: :ok
  def insert(server, user_id, provider, attrs \\ %{})
      when (is_pid(server) or is_atom(server)) and is_binary(user_id) and is_atom(provider) and is_map(attrs) do
    GenServer.call(server, {:insert, user_id, provider, attrs})
  end

  @doc """
  Updates provider data by merging with existing data.
  New data takes priority over existing data.

  ## Examples
      iex> Songy.Providers.insert(:providers, "user123", :spotify, %{access_token: "token1"})
      :ok
      iex> Songy.Providers.update(:providers, "user123", :spotify, %{device_id: "device1"})
      :ok
      # Result: %{access_token: "token1", device_id: "device1"}
  """
  @spec update(GenServer.server(), String.t(), atom(), map()) :: :ok
  def update(server, user_id, provider, new_data)
      when (is_pid(server) or is_atom(server)) and is_binary(user_id) and is_atom(provider) and is_map(new_data) do
    GenServer.call(server, {:update, user_id, provider, new_data})
  end

  @doc """
  Looks up the provider data for user. Automatically refreshes tokens if they're close to expiry.

  ## Examples
      iex> {:ok, pid} = Songy.Providers.start_link(name: :providers)
      iex> Songy.Providers.lookup(:providers, "user123")
      {:ok, {:spotify, %{access_token: "fresh_token", refresh_token: "refresh"}}}

      iex> Songy.Providers.lookup(:providers, "unknown_user")
      {:error, :not_found}
  """
  @spec lookup(term(), String.t()) :: {:ok, {atom(), map()}} | {:error, atom()}
  def lookup(registry, user_id) when is_binary(user_id) do
    with [{^user_id, {provider, data}}] <- :ets.lookup(registry, user_id),
         {:ok, provider_data} <- ensure_data(provider, data),
         {:match, true, _, _} <- {:match, match?(^data, provider_data), provider, provider_data} do
      {:ok, {provider, data}}
    else
      {:match, false, provider, updated_data} ->
        GenServer.call(registry, {:update, user_id, provider, updated_data})
        {:ok, {provider, updated_data}}

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
  def handle_call({:insert, user_id, provider, attrs}, _from, table) do
    :ets.insert(table, {user_id, {provider, attrs}})
    Logger.debug("Inserted #{provider} data for user #{user_id}")

    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:update, user_id, provider, new_data}, _from, table) do
    merged_data =
      :ets.lookup(table, user_id)
      |> case do
        [{^user_id, {^provider, data}}] -> data
        _ -> %{}
      end
      |> Map.merge(new_data)

    :ets.insert(table, {user_id, {provider, merged_data}})
    Logger.debug("Updated #{provider} data for user #{user_id}")
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

  defp ensure_data(:spotify, data) do
    Songy.Boundary.Spotify.ensure_provider_data(data)
  end

  defp ensure_data(_provider, data) do
    {:ok, data}
  end
end
