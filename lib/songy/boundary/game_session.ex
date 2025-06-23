defmodule Songy.Boundary.GameSession do
  @moduledoc """
  GenServer for managing game session state and player interactions.

  Each game session is a separate process that maintains the state of
  an active game room. Sessions are dynamically created and supervised
  by the GameSession supervisor.
  """

  use GenServer

  alias Songy.Core.Game

  require Logger

  @doc """
  Starts a new game session process.

  ## Parameters
    * `game` - The Game struct to initialize the session with

  ## Examples
      iex> game = Game.new()
      iex> GameSession.start_game(game)
      {:ok, #PID<0.123.0>}
  """
  @spec start_game(Game.t()) :: {:ok, pid()} | {:error, term()}
  def start_game(%Game{} = game) do
    DynamicSupervisor.start_child(
      Songy.Supervisor.GameSession,
      {__MODULE__, game}
    )
  end

  @doc """
  Adds a user to the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `user_uuid` - UUID of the user to add

  ## Examples
      iex> GameSession.add_user("game123", "user456")
      {:ok, %Game{participants: [%User{uuid: "user456"}]}}

      iex> GameSession.add_user("game123", "existing_user")
      {:error, :user_already_joined}
  """
  @spec add_user(String.t(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def add_user(game_uuid, user_uuid) do
    GenServer.call(via(game_uuid), {:add_user, user_uuid})
  catch
    :exit, _ -> {:error, :not_found}
  end

  @doc """
  Terminates a game session.

  ## Parameters
    * `game_uuid` - UUID of the game to terminate
  """
  @spec end_game(String.t()) :: :ok
  def end_game(game_uuid) do
    GenServer.stop(via(game_uuid))
  catch
    :exit, _ -> :ok
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
  def handle_call({:add_user, user_uuid}, _from, game) do
    user = %Songy.Core.User{uuid: user_uuid}

    case Game.add_participant(game, user) do
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
