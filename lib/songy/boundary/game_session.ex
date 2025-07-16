defmodule Songy.Boundary.GameSession do
  @moduledoc """
  GenServer for managing game session state and player interactions.

  Each game session is a separate process that maintains the state of
  an active game room. Sessions are dynamically created and supervised
  by the GameSession supervisor.

  ## Public API

    * `create_game_session/2` - Creates and starts a new game session process with owner and provider
    * `add_participant/2` - Adds a participant to an existing game session
    * `remove_participant/2` - Removes a participant from an existing game session
    * `get_game_session/1` - Retrieves the current state of a game session
    * `start_game_session/1` - Starts the game by changing its status to in_progress
    * `end_game_session/1` - Terminates a game session process
    * `owner?/2` - Checks if a user is the owner of a game session
    * `update_provider/2` - Updates the provider for a game session (owner only)

  ## Process Management

  Game sessions are registered in `Songy.Registry` using their UUID as the key.
  This allows for efficient lookup and ensures uniqueness across all sessions.

  Sessions are supervised by `Songy.Supervisor.GameSession` and will be
  automatically restarted if they crash unexpectedly.
  """

  use GenServer

  alias Songy.Core.{Game, User, Provider}

  require Logger

  @doc """
  Creates and starts a new game session process with specified owner and provider.

  Generates a new game with a random UUID and starts the session process.

  ## Parameters
    * `owner_uuid` - UUID of the user who will own the game room
    * `provider` - Provider instance for the game

  ## Examples
      iex> GameSession.create_game_session("user123", %Provider{id: :spotify})
      {:ok, %Game{uuid: "a1b2c3", participants: [], owner_uuid: "user123", provider: %Provider{id: :spotify}}}

      iex> GameSession.create_game_session("invalid", %Provider{id: :spotify})
      {:error, :process_start_failed}
  """
  @spec create_game_session(String.t(), Provider.t()) :: {:ok, Game.t()} | {:error, term()}
  def create_game_session(owner_uuid, %Provider{} = provider) when is_binary(owner_uuid) do
    with game <- Game.new(owner_uuid, provider: provider),
         {:ok, _pid} <-
           DynamicSupervisor.start_child(
             Songy.Supervisor.GameSession,
             {__MODULE__, game}
           ) do
      {:ok, game}
    else
      {:error, {:already_started, _pid}} -> {:error, :already_exists}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Adds a participant to the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `participant_uuid` - UUID of the participant to add

  ## Examples
      iex> GameSession.add_participant("game123", "user456")
      {:ok, %Game{participants: [%User{uuid: "user456"}]}}

      iex> GameSession.add_participant("game123", "existing_user")
      {:error, :user_already_joined}
  """
  @spec add_participant(String.t(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def add_participant(game_uuid, participant_uuid) do
    if session_exists?(game_uuid) do
      GenServer.call(via(game_uuid), {:add_participant, participant_uuid})
    else
      {:error, :not_found}
    end
  end

  @doc """
  Terminates a game session.

  ## Parameters
    * `game_uuid` - UUID of the game session to terminate
  """
  @spec end_game_session(String.t()) :: :ok
  def end_game_session(game_uuid) do
    if session_exists?(game_uuid) do
      GenServer.stop(via(game_uuid))
    else
      :ok
    end
  end

  @doc """
  Removes a participant from the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `participant_uuid` - UUID of the participant to remove

  ## Examples
      iex> GameSession.remove_participant("game123", "user456")
      {:ok, %Game{participants: []}}

      iex> GameSession.remove_participant("game123", "nonexistent_user")
      {:error, :user_not_found}
  """
  @spec remove_participant(String.t(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def remove_participant(game_uuid, participant_uuid) do
    if session_exists?(game_uuid) do
      GenServer.call(via(game_uuid), {:remove_participant, participant_uuid})
    else
      {:error, :not_found}
    end
  end

  @doc """
  Gets the current state of the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session

  ## Examples
      iex> GameSession.get_game_session("game123")
      {:ok, %Game{uuid: "game123", participants: []}}

      iex> GameSession.get_game_session("nonexistent")
      {:error, :not_found}
  """
  @spec get_game_session(String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def get_game_session(game_uuid) do
    if session_exists?(game_uuid) do
      GenServer.call(via(game_uuid), :get_game_session)
    else
      {:error, :not_found}
    end
  end

  @doc """
  Starts the game by changing its status to in_progress.

  ## Parameters
    * `game_uuid` - UUID of the game session

  ## Examples
      iex> GameSession.start_game_session("game123")
      {:ok, %Game{status: :in_progress}}

      iex> GameSession.start_game_session("nonexistent")
      {:error, :not_found}
  """
  @spec start_game_session(String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def start_game_session(game_uuid) do
    if session_exists?(game_uuid) do
      GenServer.call(via(game_uuid), :start_game_session)
    else
      {:error, :not_found}
    end
  end

  @doc """
  Checks if the given user is the owner of the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `user_uuid` - UUID of the user to check

  ## Examples
      iex> GameSession.owner?("game123", "owner456")
      true

      iex> GameSession.owner?("game123", "participant789")
      false
  """
  @spec owner?(String.t(), String.t()) :: boolean()
  def owner?(game_uuid, user_uuid) do
    case get_game_session(game_uuid) do
      {:ok, game} -> Game.owner?(game, user_uuid)
      {:error, _} -> false
    end
  end

  @doc """
  Updates the provider for the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `provider_data` - Map containing provider id and meta (%{id: atom(), meta: map()})

  ## Examples
      iex> GameSession.update_provider("game123", %{id: :spotify, meta: %{device_id: "abc123"}})
      {:ok, %Game{provider: %Provider{id: :spotify, meta: %{device_id: "abc123"}}}}

      iex> GameSession.update_provider("nonexistent", %{id: :spotify, meta: %{}})
      {:error, :not_found}
  """
  @spec update_provider(String.t(), map()) :: {:ok, Game.t()} | {:error, atom()}
  def update_provider(game_uuid, attrs) do
    with {:ok, game} <- lookup_game_session(game_uuid),
         %Provider{} = provider <- Provider.update(game.provider, attrs) do
      GenServer.call(via(game_uuid), {:update_provider, provider})
    else
      error -> error
    end
  end

  def session_exists?(game_uuid) do
    match?([_], Registry.lookup(Songy.Registry, game_uuid))
  end

  @spec lookup_game_session(String.t()) :: {:ok, Game.t()} | {:error, :not_found}
  def lookup_game_session(game_uuid) do
    case Registry.lookup(Songy.Registry, game_uuid) do
      [{pid, _value}] -> GenServer.call(pid, :get_game_session, 1000)
      [] -> {:error, :not_found}
    end
  rescue
    _ -> {:error, :not_found}
  catch
    _, _ -> {:error, :not_found}
  end

  def child_spec(game) do
    %{
      id: {__MODULE__, game.uuid},
      start: {__MODULE__, :start_link, [game]},
      restart: :temporary
    }
  end

  def start_link(%Game{} = game) do
    GenServer.start_link(
      __MODULE__,
      game,
      name: via(game.uuid)
    )
  end

  @impl GenServer
  def init(%Game{} = game) do
    Logger.info("Starting game session for game #{game.uuid}")

    {:ok, game}
  end

  @impl GenServer
  def handle_call({:add_participant, participant_uuid}, _from, game) do
    user = User.get_user(participant_uuid)

    case Game.add_participant(game, user) do
      {:ok, updated_game} ->
        {:reply, {:ok, updated_game}, updated_game}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  @impl GenServer
  def handle_call({:remove_participant, participant_uuid}, _from, game) do
    case Game.remove_participant(game, participant_uuid) do
      {:ok, updated_game} ->
        {:reply, {:ok, updated_game}, updated_game}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  @impl GenServer
  def handle_call(:get_game_session, _from, game) do
    {:reply, {:ok, game}, game}
  end

  @impl GenServer
  def handle_call(:start_game_session, _from, game) do
    case game.status do
      :waiting ->
        updated_game = %{game | status: :in_progress}
        {:reply, {:ok, updated_game}, updated_game}

      _ ->
        {:reply, {:error, :game_already_started}, game}
    end
  end

  @impl GenServer
  def handle_call({:update_provider, provider}, _from, game) do
    updated_game = Game.update_provider(game, provider)

    {:reply, {:ok, updated_game}, updated_game}
  end

  @impl GenServer
  def terminate(reason, game) do
    Logger.info("Game session #{game.uuid} terminated: #{inspect(reason)}")
    :ok
  end

  defp via(game_uuid) do
    {:via, Registry, {Songy.Registry, game_uuid}}
  end
end
