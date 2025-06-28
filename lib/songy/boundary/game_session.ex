defmodule Songy.Boundary.GameSession do
  @moduledoc """
  GenServer for managing game session state and player interactions.

  Each game session is a separate process that maintains the state of
  an active game room. Sessions are dynamically created and supervised
  by the GameSession supervisor.

  ## Public API

    * `start_game_session/0` - Creates and starts a new game session process
    * `add_participant/2` - Adds a participant to an existing game session
    * `remove_participant/2` - Removes a participant from an existing game session
    * `get_game_session/1` - Retrieves the current state of a game session
    * `end_game_session/1` - Terminates a game session process

  ## Process Management

  Game sessions are registered in `Songy.Registry` using their UUID as the key.
  This allows for efficient lookup and ensures uniqueness across all sessions.

  Sessions are supervised by `Songy.Supervisor.GameSession` and will be
  automatically restarted if they crash unexpectedly.
  """

  use GenServer

  alias Songy.Core.{Game, User}

  require Logger

  @doc """
  Creates and starts a new game session process.

  Generates a new game with a random UUID and starts the session process.

  ## Examples
      iex> GameSession.start_game_session()
      {:ok, %Game{uuid: "a1b2c3", participants: []}}

      iex> GameSession.start_game_session()
      {:error, :process_start_failed}
  """
  @spec start_game_session() :: {:ok, Game.t()} | {:error, term()}
  def start_game_session do
    with game <- Game.new(),
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
      GenServer.call(via(game_uuid), :get_game)
    else
      {:error, :not_found}
    end
  end

  def session_exists?(game_uuid) do
    match?([_], Registry.lookup(Songy.Registry, game_uuid))
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
  def handle_call(:get_game, _from, game) do
    {:reply, {:ok, game}, game}
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
