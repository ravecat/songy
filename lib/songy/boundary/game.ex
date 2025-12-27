defmodule Songy.Boundary.Game do
  @moduledoc """
  Game FSM managing game lifecycle using GenStateMachine.

  States:
  - `{:waiting, :none}` - Lobby phase, participants can join/leave
  - `{:in_progress, turn_phase}` - Active gameplay with turn phases
  - `{:finished, :none}` - Game completed, read-only

  The FSM manages game state transitions and validates operations based on current state.
  """

  use GenStateMachine, callback_mode: :handle_event_function

  alias Songy.Boundary.Player, as: Playback
  alias Songy.Core, as: Core
  alias SongyWeb.Presence

  require Logger

  def child_spec(opts) do
    game_id = Keyword.fetch!(opts, :id)

    %{
      id: {__MODULE__, game_id},
      start: {__MODULE__, :start_link, [opts]},
      restart: :temporary
    }
  end

  @doc "Starts a game FSM process"
  def start_link(opts) do
    game_id = Keyword.fetch!(opts, :id)
    GenStateMachine.start_link(__MODULE__, opts, name: via(game_id))
  end

  @doc "Looks up the game process PID by id."
  def lookup_game(game_id) do
    case Registry.lookup(Songy.Registry, {:game, game_id}) do
      [{pid, _value}] -> {:ok, pid}
      [] -> {:error, :game_session_not_found}
    end
  end

  @doc "Checks whether a game process exists for the given id."
  def game_exists?(game_id) do
    case lookup_game(game_id) do
      {:ok, pid} -> Process.alive?(pid)
      {:error, _} -> false
    end
  end

  @doc "Fetches the current game state."
  def get_state(game_id, timeout \\ 1_000) do
    call_if_exists(game_id, :get_state, timeout)
  end

  @doc "Checks whether the given user is the owner of the game."
  def owner?(game_id, user_id) do
    case get_state(game_id) do
      {:ok, %{owner_id: ^user_id}} -> true
      {:error, _} -> false
    end
  end

  @doc "Starts the game."
  def start_game(game_id, timeout \\ 1_000) do
    call_if_exists(game_id, :start_game, timeout)
  end

  @doc "Starts playback."
  def start_playback(game_id, timeout \\ 1_000) do
    call_if_exists(game_id, :start_playback, timeout)
  end

  @doc "Pauses playback."
  def pause_playback(game_id, timeout \\ 1_000) do
    call_if_exists(game_id, :pause_playback, timeout)
  end

  @doc "Advances to the next phase."
  def next_phase(game_id, timeout \\ 1_000) do
    call_if_exists(game_id, :next_phase, timeout)
  end

  @doc "Adds an assumption for a user at the specified position."
  def make_assumption(game_id, user_id, position \\ 0, timeout \\ 1_000) do
    call_if_exists(game_id, {:make_assumption, user_id, position}, timeout)
  end

  @doc "Reorders a user's timeline entry to a new position."
  def reorder_timeline(game_id, user_id, position \\ 0, timeout \\ 1_000) do
    call_if_exists(game_id, {:reorder_timeline, user_id, position}, timeout)
  end

  @doc "Increments a user's score by the provided points."
  def increment_score(game_id, user_id, points \\ 1, timeout \\ 1_000) do
    call_if_exists(game_id, {:increment_score, user_id, points}, timeout)
  end

  @doc "Gets the active player UUID from the queue."
  def get_active_player(game_id, timeout \\ 1_000) do
    call_if_exists(game_id, :get_active_player, timeout)
  end

  @doc "Sets the current track."
  def set_track(game_id, track, timeout \\ 1_000) do
    call_if_exists(game_id, {:set_track, track}, timeout)
  end

  @doc "Gets the current track."
  def get_track(game_id, timeout \\ 1_000) do
    call_if_exists(game_id, :get_track, timeout)
  end

  # GenStateMachine Callbacks

  @impl true
  def init(opts) do
    game = %Core.Game{
      id: Keyword.fetch!(opts, :id),
      owner_id: Keyword.fetch!(opts, :owner_id),
      max_participants: Keyword.get(opts, :max_participants, 10),
      max_score: Keyword.get(opts, :max_score, 10),
      status: :waiting,
      participants: [],
      scores: %{},
      player: Core.Player.new(),
      timelines: %{},
      created_at: DateTime.utc_now(),
      queue: [],
      cursor: 0,
      track: nil,
      turn: nil
    }

    Presence.subscribe(game.id)

    {:ok, {:waiting, :none}, game}
  end

  # State: :waiting (lobby phase)

  @impl true
  def handle_event(:info, {:participant_joined, user_id}, {:waiting, :none}, data) do
    handle_presence_joined(data, user_id)
  end

  def handle_event(:info, {:participant_left, user_id}, {:waiting, :none}, data) do
    handle_presence_left(data, user_id)
  end

  def handle_event({:call, from}, :start_game, {:waiting, :none}, data) do
    Logger.info("Game #{data.id}: Starting game")

    with :ok <- Core.Game.validate_min_participants(data) do
      game = %{
        data
        | status: :in_progress,
          turn: %Core.Turn{phase: :waiting, timeline: [], assumptions: []}
      }

      {:next_state, {:in_progress, :waiting}, game, [{:reply, from, {:ok, game}}]}
    else
      {:error, reason} = error ->
        Logger.warning("Game #{data.id}: Failed to start - #{reason}")
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def handle_event({:call, from}, :get_state, {:waiting, :none}, data) do
    {:keep_state, data, [{:reply, from, {:ok, data}}]}
  end

  def handle_event({:call, from}, :get_active_player, {:waiting, :none}, %{queue: queue, cursor: cursor} = data) do
    active_player = Enum.at(queue, cursor)
    {:keep_state, data, [{:reply, from, {:ok, active_player}}]}
  end

  def handle_event({:call, from}, {:set_track, track}, {:waiting, :none}, data) do
    new_data = %{data | track: track}
    {:keep_state, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def handle_event({:call, from}, :get_track, {:waiting, :none}, %{track: nil} = data) do
    {:keep_state, data, [{:reply, from, {:error, :no_current_track}}]}
  end

  def handle_event({:call, from}, :get_track, {:waiting, :none}, %{track: track} = data) do
    {:keep_state, data, [{:reply, from, {:ok, track}}]}
  end

  def handle_event({:call, from}, _event, {:waiting, :none}, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :in_progress (active gameplay)

  def handle_event(:info, {:participant_joined, user_id}, {:in_progress, _phase}, data) do
    handle_presence_joined(data, user_id)
  end

  def handle_event(:info, {:participant_left, user_id}, {:in_progress, _phase}, data) do
    handle_presence_left(data, user_id)
  end

  def handle_event(:timeout, :auto_advance, {:in_progress, :challenging}, %{turn: turn} = data) do
    Logger.debug("Game #{data.id}: Challenging phase timeout - auto-advancing to results")

    updated_game = apply_challenging_results(data, turn)
    updated_game = %{updated_game | turn: %{turn | phase: :results}}

    {:next_state, {:in_progress, :results}, updated_game}
  end

  def handle_event(:info, _event, {:in_progress, _phase}, data) do
    {:keep_state, data}
  end

  def handle_event({:call, from}, :start_game, {:in_progress, _phase}, data) do
    {:keep_state, data, [{:reply, from, {:error, :game_already_started}}]}
  end

  def handle_event({:call, from}, :next_phase, {:in_progress, :waiting}, data) do
    Logger.debug("Game #{data.id}: Advancing turn phase")

    updated_game = snapshot_active_user_timeline(data)
    turn = updated_game.turn
    updated_game = %{updated_game | turn: %{turn | phase: :ready}}

    {:next_state, {:in_progress, :ready}, updated_game, [{:reply, from, {:ok, updated_game}}]}
  end

  def handle_event({:call, from}, :next_phase, {:in_progress, :ready}, %{turn: turn} = data) do
    Logger.debug("Game #{data.id}: Advancing turn phase")

    updated_game = %{data | turn: %{turn | phase: :steady}}

    {:next_state, {:in_progress, :steady}, updated_game, [{:reply, from, {:ok, updated_game}}]}
  end

  def handle_event({:call, from}, :next_phase, {:in_progress, :steady}, %{turn: turn} = data) do
    Logger.debug("Game #{data.id}: Advancing turn phase")

    updated_game = %{data | turn: %{turn | phase: :challenging}}
    timeout = Application.fetch_env!(:songy, :challenging_phase_timeout)

    {:next_state, {:in_progress, :challenging}, updated_game,
     [{:reply, from, {:ok, updated_game}}, {:timeout, timeout, :auto_advance}]}
  end

  def handle_event({:call, from}, :next_phase, {:in_progress, :challenging}, %{turn: turn} = data) do
    Logger.debug("Game #{data.id}: Advancing turn phase")

    updated_game = apply_challenging_results(data, turn)
    updated_game = %{updated_game | turn: %{turn | phase: :results}}

    reply = [{:reply, from, {:ok, updated_game}}]

    {:next_state, {:in_progress, :results}, updated_game, reply}
  end

  def handle_event({:call, from}, :next_phase, {:in_progress, :results}, data) do
    Logger.debug("Game #{data.id}: Advancing turn phase")

    with :no_winner <- Core.Game.check_winner(data),
         {:ok, provider} <- Songy.Providers.lookup(:providers, data.owner_id),
         {:ok, %Core.Track{} = track} <- Playback.search_random_track(provider),
         {:ok, :playback_paused} <- Playback.pause_playback(provider) do
      updated_game = %{
        data
        | player: Core.Player.set_playback(data.player, false),
          track: track,
          cursor: next_cursor(data.cursor, data.queue),
          turn: %Core.Turn{phase: :waiting, timeline: [], assumptions: []}
      }

      {:next_state, {:in_progress, :waiting}, updated_game, [{:reply, from, {:ok, updated_game}}]}
    else
      {:winner, _winner_id} ->
        game = %{data | status: :finished}
        timeout = Application.fetch_env!(:songy, :game_session_termination_timeout)

        {:next_state, {:finished, :none}, game, [{:reply, from, {:ok, game}}, {:state_timeout, timeout, :shutdown}]}

      {:error, reason} ->
        {:keep_state, data, [{:reply, from, {:error, reason}}]}
    end
  end

  def handle_event(
        {:call, from},
        {:make_assumption, user_id, position},
        {:in_progress, :challenging},
        %{track: track, turn: turn} = data
      ) do
    Logger.debug("Game #{data.id}: Making assumption for #{user_id} at #{position}")

    if is_nil(track) do
      {:keep_state, data, [{:reply, from, {:error, :no_current_track}}]}
    else
      updated_turn = do_update_timeline(turn, track, user_id, position)
      updated_game = %{data | turn: updated_turn}

      {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
    end
  end

  def handle_event(
        {:call, from},
        {:reorder_timeline, user_id, position},
        {:in_progress, :challenging},
        %{turn: turn} = data
      ) do
    Logger.debug("Game #{data.id}: Reordering timeline for #{user_id} to #{position}")

    case reorder_timeline_logic(turn, user_id, position) do
      {:ok, updated_turn} ->
        updated_game = %{data | turn: updated_turn}

        {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}

      {:error, reason} ->
        {:keep_state, data, [{:reply, from, {:error, reason}}]}
    end
  end

  def handle_event({:call, from}, :start_playback, {:in_progress, _phase}, data) do
    updated_game = %{data | player: Core.Player.set_playback(data.player, true)}

    {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
  end

  def handle_event({:call, from}, :pause_playback, {:in_progress, _phase}, data) do
    updated_game = %{data | player: Core.Player.set_playback(data.player, false)}

    {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
  end

  def handle_event({:call, from}, {:increment_score, user_id, points}, {:in_progress, _phase}, data) do
    Logger.debug("Game #{data.id}: Incrementing score for #{user_id} by #{points}")

    updated_scores = Map.update(data.scores, user_id, points, &(&1 + points))
    updated_game = %{data | scores: updated_scores}

    with {:winner, winner_uuid} <- Core.Game.check_winner(updated_game) do
      Logger.info("Game #{data.id}: Game won by #{winner_uuid}")

      finished_game = %{updated_game | status: :finished}

      timeout = Application.fetch_env!(:songy, :game_session_termination_timeout)

      {:next_state, {:finished, :none}, finished_game,
       [{:reply, from, {:ok, finished_game}}, {:state_timeout, timeout, :shutdown}]}
    else
      :no_winner ->
        {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
    end
  end

  def handle_event({:call, from}, :get_state, {:in_progress, _phase}, data) do
    {:keep_state, data, [{:reply, from, {:ok, data}}]}
  end

  def handle_event({:call, from}, :get_active_player, {:in_progress, _phase}, %{queue: queue, cursor: cursor} = data) do
    active_player = Enum.at(queue, cursor)
    {:keep_state, data, [{:reply, from, {:ok, active_player}}]}
  end

  def handle_event({:call, from}, {:set_track, track}, {:in_progress, _phase}, data) do
    new_data = %{data | track: track}
    {:keep_state, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def handle_event({:call, from}, :get_track, {:in_progress, _phase}, %{track: track} = data) do
    response = if is_nil(track), do: {:error, :no_current_track}, else: {:ok, track}
    {:keep_state, data, [{:reply, from, response}]}
  end

  def handle_event({:call, from}, _event, {:in_progress, _phase}, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :finished (game completed)

  def handle_event(:state_timeout, :shutdown, {:finished, :none}, data) do
    {:stop, :normal, data}
  end

  def handle_event(:info, {:participant_joined, _user_id}, {:finished, :none}, data) do
    {:keep_state, data}
  end

  def handle_event(:info, {:participant_left, _user_id}, {:finished, :none}, data) do
    {:keep_state, data}
  end

  def handle_event({:call, from}, :get_state, {:finished, :none}, data) do
    {:keep_state, data, [{:reply, from, {:ok, data}}]}
  end

  def handle_event({:call, from}, :get_active_player, {:finished, :none}, %{queue: queue, cursor: cursor} = data) do
    {:keep_state, data, [{:reply, from, {:ok, Enum.at(queue, cursor)}}]}
  end

  def handle_event({:call, from}, :get_track, {:finished, :none}, %{track: nil} = data) do
    {:keep_state, data, [{:reply, from, {:error, :no_current_track}}]}
  end

  def handle_event({:call, from}, :get_track, {:finished, :none}, %{track: track} = data) do
    {:keep_state, data, [{:reply, from, {:ok, track}}]}
  end

  def handle_event({:call, from}, _event, {:finished, :none}, data) do
    {:keep_state, data, [{:reply, from, {:error, :game_finished}}]}
  end

  defp handle_presence_joined(data, user_id) do
    user = Core.User.get_user(user_id)

    with :ok <- Core.Game.validate_not_full(data),
         :ok <- Core.Game.validate_not_duplicate(data, user) do
      updated_game = %{
        data
        | participants: data.participants ++ [user],
          scores: Map.put(data.scores, user.uuid, 0),
          queue: data.queue ++ [user.uuid]
      }

      broadcast_game_state(updated_game)

      {:keep_state, updated_game}
    else
      {:error, reason} ->
        Logger.debug("Game #{data.id}: Skipping participant #{user_id} - #{reason}")
        {:keep_state, data}
    end
  end

  defp handle_presence_left(data, user_id) do
    case Enum.find_index(data.participants, &(&1.uuid == user_id)) do
      nil ->
        {:keep_state, data}

      _index ->
        updated_game =
          remove_player_from_queue(
            %{
              data
              | participants: Enum.reject(data.participants, &(&1.uuid == user_id)),
                scores: Map.delete(data.scores, user_id)
            },
            user_id
          )

        broadcast_game_state(updated_game)

        {:keep_state, updated_game}
    end
  end

  defp broadcast_game_state(game) do
    if Process.whereis(Songy.PubSub) do
      Phoenix.PubSub.local_broadcast(
        Songy.PubSub,
        "room:#{game.id}",
        {:game_state_updated, game}
      )
    end

    :ok
  end

  defp snapshot_active_user_timeline(game) do
    active_player = Enum.at(game.queue, game.cursor)

    if is_binary(active_player) do
      timeline = get_user_timeline(game, active_player)
      turn = game.turn
      %{game | turn: %{turn | timeline: timeline}}
    else
      game
    end
  end

  defp do_update_timeline(%Core.Turn{} = turn, track, user_id, position) do
    case Enum.find_index(turn.timeline, fn t -> t.id == track.id end) do
      nil ->
        {before, after_items} = Enum.split(turn.timeline, position)
        new_timeline = before ++ [track] ++ after_items

        new_assumptions =
          turn.assumptions
          |> Enum.reject(&(&1.user_id == user_id))
          |> Enum.map(fn
            %{position: pos} = assumption when pos >= position ->
              %{assumption | position: pos + 1}

            assumption ->
              assumption
          end)
          |> Enum.concat([%{position: position, user_id: user_id}])

        %{turn | timeline: new_timeline, assumptions: new_assumptions}

      _index ->
        turn
    end
  end

  defp reorder_timeline_logic(%Core.Turn{} = turn, user_id, new_position) do
    case Enum.find_index(turn.assumptions, fn %{user_id: uid} -> uid == user_id end) do
      nil ->
        {:error, :user_assumption_not_found}

      index ->
        assumption = Enum.at(turn.assumptions, index)
        old_position = assumption.position

        if old_position == new_position do
          {:ok, turn}
        else
          track = Enum.at(turn.timeline, old_position)
          new_timeline = List.delete_at(turn.timeline, old_position)
          {before, after_items} = Enum.split(new_timeline, new_position)
          new_timeline = before ++ [track] ++ after_items

          new_assumptions =
            Enum.map(turn.assumptions, fn
              %{position: pos} = assumption when pos == old_position ->
                %{assumption | position: new_position}

              %{position: pos} = assumption when old_position < pos and pos <= new_position ->
                %{assumption | position: pos - 1}

              %{position: pos} = assumption when new_position <= pos and pos < old_position ->
                %{assumption | position: pos + 1}

              assumption ->
                assumption
            end)

          {:ok, %{turn | timeline: new_timeline, assumptions: new_assumptions}}
        end
    end
  end

  defp apply_challenging_results(game, turn) do
    track = game.track

    game =
      case Enum.find(turn.assumptions, &Core.Game.valid_assumption?(turn.timeline, &1.position)) do
        %{user_id: user_id} ->
          game
          |> increment_user_score_local(user_id, 1)
          |> extend_user_timeline(user_id, track)

        nil ->
          game
      end

    game
  end

  defp remove_player_from_queue(game, player_uuid) do
    case Enum.find_index(game.queue, &(&1 == player_uuid)) do
      nil ->
        game

      player_index ->
        new_queue = List.delete_at(game.queue, player_index)

        new_cursor =
          cond do
            player_index < game.cursor -> game.cursor - 1
            player_index == game.cursor -> game.cursor
            player_index > game.cursor -> game.cursor
          end

        adjusted_cursor =
          if length(new_queue) > 0 do
            rem(new_cursor, length(new_queue))
          else
            0
          end

        %{game | queue: new_queue, cursor: adjusted_cursor}
    end
  end

  defp next_cursor(cursor, queue) do
    rem(cursor + 1, max(length(queue), 1))
  end

  defp get_user_timeline(game, user_id) when is_binary(user_id) do
    Map.get(game.timelines, user_id, [])
  end

  defp extend_user_timeline(game, _user_id, nil), do: game

  defp extend_user_timeline(game, user_id, %Core.Track{} = track) when is_binary(user_id) do
    current_timeline = get_user_timeline(game, user_id)

    position =
      Enum.find_index(current_timeline, &(&1.year > track.year)) || length(current_timeline)

    updated_timeline = List.insert_at(current_timeline, position, track)

    %{game | timelines: Map.put(game.timelines, user_id, updated_timeline)}
  end

  defp increment_user_score_local(game, user_id, points) do
    updated_scores = Map.update(game.scores, user_id, points, &(&1 + points))
    %{game | scores: updated_scores}
  end

  defp call_if_exists(game_id, message, timeout) do
    case lookup_game(game_id) do
      {:ok, _pid} -> GenStateMachine.call(via(game_id), message, timeout)
      {:error, _} = error -> error
    end
  rescue
    _ -> {:error, :game_session_not_found}
  catch
    _, _ -> {:error, :game_session_not_found}
  end

  defp via(game_id) do
    {:via, Registry, {Songy.Registry, {:game, game_id}}}
  end
end
