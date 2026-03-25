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
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Inserts or updates provider data for a specific user.

  ## Examples
      iex> spotify_data = %Songy.Core.Provider.Spotify{access_token: "token"}
      iex> Songy.Providers.insert("user123", spotify_data)
      :ok
  """
  @spec insert(String.t(), term()) :: :ok
  def insert(user_id, data) do
    GenServer.call(__MODULE__, {:insert, user_id, data})
  end

  @doc """
  Updates provider data for a specific user.

  ## Examples
      iex> new_data = %Songy.Core.Provider.Spotify{access_token: "token1", device_id: "device1"}
      iex> Songy.Providers.update("user123", new_data)
      :ok
  """
  @spec update(String.t(), term()) :: :ok
  def update(user_id, attrs) do
    GenServer.call(__MODULE__, {:update, user_id, attrs})
  end

  @doc false
  @spec clear() :: :ok
  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  @doc """
  Ensures provider is ready for the user.
  Returns {:ok, id, provider} from ETS (validated and refreshed) or creates the default provider.
  """
  @spec ensure(String.t()) :: {:ok, atom(), struct()} | {:error, atom()}
  def ensure(user_id) do
    with {:ok, provider} <- lookup(user_id),
         {:ok, id, ^provider} <- Songy.Boundary.Provider.ensure(provider) do
      {:ok, id, provider}
    else
      {:ok, id, refreshed} ->
        update(user_id, refreshed)
        {:ok, id, refreshed}

      {:error, :invalid_credentials} ->
        remove(user_id)
        insert_default_provider(user_id)

      {:error, :not_found} ->
        insert_default_provider(user_id)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp insert_default_provider(user_id) do
    module =
      Application.fetch_env!(:songy, :providers)
      |> Keyword.fetch!(:default)

    provider = module.new()
    insert(user_id, provider)
    Songy.Boundary.Provider.ensure(provider)
  end

  @doc """
  Looks up the provider data for user. Pure ETS read without validation.
  """
  @spec lookup(String.t()) :: {:ok, struct()} | {:error, :not_found}
  def lookup(user_id) when is_binary(user_id) do
    case :ets.lookup(__MODULE__, user_id) do
      [{^user_id, data}] -> {:ok, data}
      [] -> {:error, :not_found}
    end
  end

  @doc false
  def remove(user_id) do
    GenServer.call(__MODULE__, {:remove, user_id})
  end

  @impl true
  def init([]) do
    {:ok, :ets.new(__MODULE__, [:named_table, :set, :protected, read_concurrency: true])}
  end

  @impl true
  def handle_call({:insert, user_id, provider}, _from, table) do
    :ets.insert(table, {user_id, provider})
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
  def handle_call(:clear, _from, table) do
    :ets.delete_all_objects(table)
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
