defmodule Songy.Providers do
  @moduledoc """
  Provider data storage with ETS.

  Stores user-scoped provider sessions in memory with automatic token refresh.

  Stateless default providers such as Apple Music and iTunes are resolved from
  application config and are not treated as persisted user sessions.
  """

  use GenServer

  require Logger

  alias Songy.Provider.Session

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
  @spec insert(String.t(), Session.t() | struct()) :: :ok
  def insert(user_id, data) do
    session = Session.normalize!(data)
    GenServer.call(__MODULE__, {:insert, user_id, session})
  end

  @doc """
  Updates provider data for a specific user.

  ## Examples
      iex> new_data = %Songy.Core.Provider.Spotify{access_token: "token1", device_id: "device1"}
      iex> Songy.Providers.update("user123", new_data)
      :ok
  """
  @spec update(String.t(), Session.t() | struct()) :: :ok
  def update(user_id, attrs) do
    session = Session.normalize!(attrs)
    GenServer.call(__MODULE__, {:update, user_id, session})
  end

  @doc false
  @spec clear() :: :ok
  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  @doc """
  Ensures provider is ready for the user.
  Returns a validated persisted provider session or falls back to the current
  default provider from application config.
  """
  @spec ensure(String.t()) :: {:ok, Session.t()} | {:error, atom()}
  def ensure(user_id) do
    with {:ok, session} <- lookup(user_id),
         {:ok, ^session} <- Songy.Boundary.Provider.ensure(session) do
      {:ok, session}
    else
      {:ok, refreshed_session} ->
        update(user_id, refreshed_session)
        {:ok, refreshed_session}

      {:error, :invalid_credentials} ->
        remove(user_id)
        insert_default_provider(user_id)

      {:error, :not_found} ->
        insert_default_provider(user_id)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp insert_default_provider(_user_id) do
    module =
      Application.fetch_env!(:songy, :providers)
      |> Keyword.fetch!(:default)

    session = Session.normalize!(module.new())

    case Songy.Boundary.Provider.ensure(session) do
      {:ok, ensured_session} -> {:ok, ensured_session}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Looks up persisted user-scoped provider data from ETS.
  """
  @spec lookup(String.t()) :: {:ok, Session.t()} | {:error, :not_found}
  def lookup(user_id) when is_binary(user_id) do
    case :ets.lookup(__MODULE__, user_id) do
      [{^user_id, data}] ->
        case Session.normalize(data) do
          {:ok, %Session{id: :spotify} = session} -> {:ok, session}
          {:ok, _session} -> {:error, :not_found}
          {:error, :not_supported} -> {:error, :not_found}
        end

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
