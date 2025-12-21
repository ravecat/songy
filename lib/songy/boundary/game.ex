defmodule Songy.Boundary.Game do
  @moduledoc """
  Game FSM managing game lifecycle using GenStateMachine.

  States:
  - `:waiting` - Lobby phase, participants can join/leave
  - `:in_progress` - Active gameplay, delegates turn operations to Turn FSM
  - `:finished` - Game completed, read-only

  The FSM manages game state transitions and validates operations based on current state.
  """

  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  alias Songy.Boundary.Turn
  alias Songy.Core.NewGame
  alias Songy.Core.Player
  alias Songy.Core.User

  require Logger

  # Client API

  @doc "Starts a game FSM process"
  def start_link(opts) do
    game_id = Keyword.fetch!(opts, :id)
    GenStateMachine.start_link(__MODULE__, opts, name: via(game_id))
  end

  @doc "Adds a participant to the game"
  def add_participant(game_id, %User{} = user) do
    GenStateMachine.call(via(game_id), {:add_participant, user})
  end

  @doc "Removes a participant from the game"
  def remove_participant(game_id, user_uuid) when is_binary(user_uuid) do
    GenStateMachine.call(via(game_id), {:remove_participant, user_uuid})
  end

  @doc "Starts the game (transitions to :in_progress)"
  def start_game(game_id) do
    GenStateMachine.call(via(game_id), :start_game)
  end

  @doc "Advances to next turn phase (delegates to Turn FSM)"
  def next_phase(game_id) do
    GenStateMachine.call(via(game_id), :next_phase)
  end

  @doc "Sets track for current turn (delegates to Turn FSM)"
  def set_track(game_id, track) do
    GenStateMachine.call(via(game_id), {:set_track, track})
  end

  @doc "Updates timeline with track at position (delegates to Turn FSM)"
  def update_timeline(game_id, track, user_uuid, position \\ 0) do
    GenStateMachine.call(via(game_id), {:update_timeline, track, user_uuid, position})
  end

  @doc "Increments user score and checks win condition"
  def increment_score(game_id, user_uuid, points \\ 1) do
    GenStateMachine.call(via(game_id), {:increment_score, user_uuid, points})
  end

  @doc "Gets current game state with turn data"
  def get_state(game_id) do
    GenStateMachine.call(via(game_id), :get_state)
  end

  # GenStateMachine Callbacks

  @impl true
  def init(opts) do
    game = %NewGame{
      id: Keyword.fetch!(opts, :id),
      owner_uuid: Keyword.fetch!(opts, :owner_uuid),
      max_participants: Keyword.get(opts, :max_participants, 10),
      max_score: Keyword.get(opts, :max_score, 10),
      status: :waiting,
      participants: [],
      scores: %{},
      player: Player.new(),
      timelines: %{},
      created_at: DateTime.utc_now(),
      turn: nil
    }

    {:ok, :waiting, game}
  end

  # State: :waiting (lobby phase)

  def waiting(:enter, _old_state, data) do
    Logger.debug("Game #{data.id}: Entered :waiting state")
    {:keep_state, data}
  end

  def waiting({:call, from}, {:add_participant, user}, data) do
    Logger.debug("Game #{data.id}: Adding participant #{user.uuid}")

    with :ok <- validate_not_full(data),
         :ok <- validate_not_duplicate(data, user) do
      updated_game = %{
        data
        | participants: [user | data.participants],
          scores: Map.put(data.scores, user.uuid, 0)
      }

      {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
    else
      {:error, reason} = error ->
        Logger.warning("Game #{data.id}: Failed to add participant - #{reason}")
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def waiting({:call, from}, {:remove_participant, user_uuid}, data) do
    Logger.debug("Game #{data.id}: Removing participant #{user_uuid}")

    case Enum.find_index(data.participants, &(&1.uuid == user_uuid)) do
      nil ->
        {:keep_state, data, [{:reply, from, {:error, :user_not_found}}]}

      _index ->
        updated_game = %{
          data
          | participants: Enum.reject(data.participants, &(&1.uuid == user_uuid)),
            scores: Map.delete(data.scores, user_uuid)
        }

        {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
    end
  end

  def waiting({:call, from}, :start_game, data) do
    Logger.info("Game #{data.id}: Starting game")

    with :ok <- validate_min_participants(data),
         {:ok, _turn_pid} <- start_turn(data) do
      updated_game = %{data | status: :in_progress}

      {:next_state, :in_progress, updated_game, [{:reply, from, {:ok, updated_game}}]}
    else
      {:error, reason} = error ->
        Logger.warning("Game #{data.id}: Failed to start - #{reason}")
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def waiting({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, build_response(data)}]}
  end

  def waiting({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :in_progress (active gameplay)

  def in_progress(:enter, _old_state, data) do
    Logger.debug("Game #{data.id}: Entered :in_progress state")
    {:keep_state, data}
  end

  def in_progress({:call, from}, {:remove_participant, user_uuid}, data) do
    Logger.debug("Game #{data.id}: Removing participant #{user_uuid} during game")

    # Cascade to Turn FSM
    if turn_pid = lookup_turn_process(data.id) do
      Turn.remove_player(turn_pid, user_uuid)
    end

    updated_game = %{
      data
      | participants: Enum.reject(data.participants, &(&1.uuid == user_uuid)),
        scores: Map.delete(data.scores, user_uuid)
    }

    {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
  end

  def in_progress({:call, from}, :next_phase, data) do
    Logger.debug("Game #{data.id}: Advancing turn phase")
    turn_pid = lookup_turn_process(data.id)

    case Turn.next_phase(turn_pid) do
      :ok ->
        {:keep_state, data, [{:reply, from, {:ok, data}}]}

      {:error, _reason} = error ->
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def in_progress({:call, from}, {:set_track, track}, data) do
    Logger.debug("Game #{data.id}: Setting track")
    turn_pid = lookup_turn_process(data.id)

    case Turn.set_track(turn_pid, track) do
      :ok ->
        {:keep_state, data, [{:reply, from, {:ok, data}}]}

      {:error, _reason} = error ->
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def in_progress({:call, from}, {:update_timeline, track, user_uuid, position}, data) do
    Logger.debug("Game #{data.id}: Updating timeline for #{user_uuid}")
    turn_pid = lookup_turn_process(data.id)

    case Turn.update_timeline(turn_pid, track, user_uuid, position) do
      :ok ->
        {:keep_state, data, [{:reply, from, {:ok, data}}]}

      {:error, _reason} = error ->
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def in_progress({:call, from}, {:increment_score, user_uuid, points}, data) do
    Logger.debug("Game #{data.id}: Incrementing score for #{user_uuid} by #{points}")

    updated_scores = Map.update(data.scores, user_uuid, points, &(&1 + points))
    updated_game = %{data | scores: updated_scores}

    case check_winner(updated_game) do
      {:winner, winner_uuid} ->
        Logger.info("Game #{data.id}: Game won by #{winner_uuid}")

        # Остановить Turn FSM
        if turn_pid = lookup_turn_process(data.id) do
          DynamicSupervisor.terminate_child(Songy.Supervisor.GameSession, turn_pid)
        end

        finished_game = %{updated_game | status: :finished, turn: nil}
        {:next_state, :finished, finished_game, [{:reply, from, {:ok, finished_game}}]}

      :no_winner ->
        {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
    end
  end

  def in_progress({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, build_response(data)}]}
  end

  def in_progress({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :finished (game completed)

  def finished(:enter, _old_state, data) do
    Logger.info("Game #{data.id}: Game finished")

    # Остановить Turn FSM если он ещё работает
    case lookup_turn_process(data.id) do
      nil ->
        :ok

      turn_pid ->
        DynamicSupervisor.terminate_child(Songy.Supervisor.GameSession, turn_pid)
    end

    {:keep_state, data}
  end

  def finished({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, build_response(data)}]}
  end

  def finished({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :game_finished}}]}
  end

  defp build_response(game) do
    turn_data = fetch_turn_state(game.id)
    %{game | turn: turn_data}
  end

  defp fetch_turn_state(game_id) do
    case lookup_turn_process(game_id) do
      nil ->
        nil

      turn_pid ->
        try do
          Turn.get_state(turn_pid)
        catch
          :exit, {:noproc, _} -> nil
          :exit, {:normal, _} -> nil
        end
    end
  end

  defp lookup_turn_process(game_id) do
    case Registry.lookup(Songy.Registry, {:turn, game_id}) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  defp start_turn(game) do
    child_spec = %{
      id: Turn,
      start: {Turn, :start_link, [game.id, [name: via_turn(game.id)]]},
      restart: :temporary
    }

    with {:ok, turn_pid} <- DynamicSupervisor.start_child(Songy.Supervisor.GameSession, child_spec) do
      Enum.each(game.participants, &Turn.add_player(turn_pid, &1.uuid))
      {:ok, turn_pid}
    end
  end

  defp via_turn(game_id) do
    {:via, Registry, {Songy.Registry, {:turn, game_id}}}
  end

  defp validate_not_full(game) do
    if length(game.participants) < game.max_participants do
      :ok
    else
      {:error, :game_full}
    end
  end

  defp validate_not_duplicate(game, user) do
    if Enum.any?(game.participants, &(&1.uuid == user.uuid)) do
      {:error, :already_joined}
    else
      :ok
    end
  end

  defp validate_min_participants(game) do
    if length(game.participants) >= 2 do
      :ok
    else
      {:error, :insufficient_participants}
    end
  end

  defp check_winner(game) do
    case Enum.find(game.scores, fn {_uuid, score} -> score >= game.max_score end) do
      {winner_uuid, _score} -> {:winner, winner_uuid}
      nil -> :no_winner
    end
  end

  defp via(game_id) do
    {:via, Registry, {Songy.Registry, {:game, game_id}}}
  end
end
