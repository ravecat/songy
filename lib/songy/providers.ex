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
  def insert(registry, user_id, data) do
    GenServer.call(registry, {:insert, user_id, data})
  end

  @doc """
  Updates provider data for a specific user.

  ## Examples
      iex> new_data = %Songy.Core.Provider.Spotify{access_token: "token1", device_id: "device1"}
      iex> Songy.Providers.update(:providers, "user123", new_data)
      :ok
  """
  @spec update(GenServer.server(), String.t(), term()) :: :ok
  def update(registry, user_id, attrs) do
    GenServer.call(registry, {:update, user_id, attrs})
  end

  @doc """
  Ensures provider is ready for the user.
  Returns :ok if ready, {:needs_auth, provider} if OAuth required.
  """
  @spec ensure_ready(GenServer.server(), String.t(), atom()) :: :ok | {:needs_auth, atom()}
  def ensure_ready(registry, user_id, :spotify) do
    case lookup(registry, user_id) do
      {:ok, %Songy.Core.Provider.Spotify{}} -> :ok
      _ -> {:redirect, :spotify}
    end
  end

  def ensure_ready(registry, user_id, :apple) do
    insert(registry, user_id, Songy.Core.Provider.Apple.new())
    :ok
  end

  def ensure_ready(registry, user_id, :itunes) do
    insert(registry, user_id, Songy.Core.Provider.ITunes.new())
    :ok
  end

  def ensure_ready(_registry, _user_id, _provider), do: :ok

  @doc """
  Returns the default provider struct based on application config.
  """
  @spec default() :: struct()
  def default do
    case Application.fetch_env!(:songy, :default_provider) do
      :itunes -> Songy.Core.Provider.ITunes.new()
      :apple -> Songy.Core.Provider.Apple.new()
    end
  end

  @doc """
  Looks up the provider data for user. Automatically refreshes tokens if they're close to expiry.
  """
  @spec lookup(term(), String.t()) :: {:ok, term()} | {:error, atom()}
  def lookup(registry, user_id) when is_binary(user_id) do
    with [{^user_id, data}] <- :ets.lookup(registry, user_id),
         {:ok, actual_data} <- Songy.Boundary.Provider.ensure(data),
         {:match, true, _} <- {:match, match?(^data, actual_data), actual_data} do
      {:ok, data}
    else
      {:match, false, actual_data} ->
        Logger.debug("Provider token refreshed for user #{user_id}")
        GenServer.call(registry, {:update, user_id, actual_data})
        {:ok, actual_data}

      [] ->
        Logger.warning("No provider found for user #{user_id}")
        {:error, :provider_not_found}

      {:error, reason} ->
        Logger.error("Provider error for user #{user_id}: #{inspect(reason)}")
        GenServer.call(registry, {:remove, user_id})
        {:error, reason}
    end
  end

  @impl true
  def init(table) do
    {:ok, :ets.new(table, [:named_table, :set, :protected, read_concurrency: true])}
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
