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

  alias Songy.Boundary.Player, as: Playback
  alias Songy.Boundary.Turn
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
      {:ok, _pid} -> true
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

  @doc "Adds a participant to the game."
  def add_participant(game_id, user, timeout \\ 1_000) do
    call_if_exists(game_id, {:add_participant, user}, timeout)
  end

  @doc "Removes a participant from the game."
  def remove_participant(game_id, user_id, timeout \\ 1_000) do
    call_if_exists(game_id, {:remove_participant, user_id}, timeout)
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

  @doc "Updates the timeline with a track at the specified position."
  def update_timeline(game_id, track, user_id, position \\ 0, timeout \\ 1_000) do
    call_if_exists(game_id, {:update_timeline, track, user_id, position}, timeout)
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

    {:ok, :waiting, game}
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

  # State: :waiting (lobby phase)

  def waiting(:enter, _old_state, data) do
    Logger.debug("Game #{data.id}: Entered :waiting state")
    {:keep_state, data}
  end

  def waiting(:info, {:participant_joined, user_id}, data) do
    handle_presence_joined(data, user_id)
  end

  def waiting(:info, {:participant_left, user_id}, data) do
    handle_presence_left(data, user_id)
  end

  def waiting({:call, from}, {:add_participant, user}, data) do
    Logger.debug("Game #{data.id}: Adding participant #{user.uuid}")

    with :ok <- validate_not_full(data),
         :ok <- validate_not_duplicate(data, user) do
      updated_game = %{
        data
        | participants: data.participants ++ [user],
          scores: Map.put(data.scores, user.uuid, 0),
          queue: data.queue ++ [user.uuid]
      }

      {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
    else
      {:error, reason} = error ->
        Logger.warning("Game #{data.id}: Failed to add participant - #{reason}")
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def waiting({:call, from}, {:remove_participant, user_id}, data) do
    Logger.debug("Game #{data.id}: Removing participant #{user_id}")

    case Enum.find_index(data.participants, &(&1.uuid == user_id)) do
      nil ->
        {:keep_state, data, [{:reply, from, {:error, :user_not_found}}]}

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

        {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
    end
  end

  def waiting({:call, from}, :start_game, data) do
    Logger.info("Game #{data.id}: Starting game")

    with :ok <- validate_min_participants(data) do
      game = %{data | status: :in_progress}

      case build_response(game) do
        {:ok, response} ->
          {:next_state, :in_progress, game, [{:reply, from, {:ok, response}}]}

        {:error, reason} ->
          {:keep_state, data, [{:reply, from, {:error, reason}}]}
      end
    else
      {:error, reason} = error ->
        Logger.warning("Game #{data.id}: Failed to start - #{reason}")
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def waiting({:call, from}, :get_state, data) do
    case build_response(data) do
      {:ok, response} -> {:keep_state, data, [{:reply, from, {:ok, response}}]}
      {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
    end
  end

  def waiting({:call, from}, :get_active_player, %{queue: queue, cursor: cursor} = data) do
    active_player = Enum.at(queue, cursor)
    {:keep_state, data, [{:reply, from, {:ok, active_player}}]}
  end

  def waiting({:call, from}, {:set_track, track}, data) do
    new_data = %{data | track: track}
    {:keep_state, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def waiting({:call, from}, :get_track, %{track: track} = data) do
    response = if is_nil(track), do: {:error, :no_current_track}, else: {:ok, track}
    {:keep_state, data, [{:reply, from, response}]}
  end

  def waiting({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :in_progress (active gameplay)

  def in_progress(:enter, _old_state, data) do
    Logger.debug("Game #{data.id}: Entered :in_progress state")
    {:keep_state, data}
  end

  def in_progress(:info, {:participant_joined, user_id}, data) do
    handle_presence_joined(data, user_id)
  end

  def in_progress(:info, {:participant_left, user_id}, data) do
    handle_presence_left(data, user_id)
  end

  def in_progress({:call, from}, :start_game, data) do
    {:keep_state, data, [{:reply, from, {:error, :game_already_started}}]}
  end

  def in_progress({:call, from}, {:remove_participant, user_id}, data) do
    Logger.debug("Game #{data.id}: Removing participant #{user_id} during game")

    updated_game =
      remove_player_from_queue(
        %{
          data
          | participants: Enum.reject(data.participants, &(&1.uuid == user_id)),
            scores: Map.delete(data.scores, user_id)
        },
        user_id
      )

    {:keep_state, updated_game, [{:reply, from, {:ok, updated_game}}]}
  end

  def in_progress({:call, from}, :next_phase, data) do
    Logger.debug("Game #{data.id}: Advancing turn phase")

    case Turn.get_state(data.id) do
      {:error, _reason} = error ->
        {:keep_state, data, [{:reply, from, error}]}

      {:ok, turn_state} ->
        case turn_state.phase do
          :waiting ->
            :ok = snapshot_active_user_timeline(data, data.id)

            case Turn.next_phase(data.id) do
              {:ok, _turn} ->
                case build_response(data) do
                  {:ok, response} -> {:keep_state, data, [{:reply, from, {:ok, response}}]}
                  {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
                end

              {:error, _reason} = error ->
                {:keep_state, data, [{:reply, from, error}]}
            end

          :steady ->
            case Turn.next_phase(data.id) do
              {:ok, _turn} ->
                schedule_challenging_timeout()

                case build_response(data) do
                  {:ok, response} -> {:keep_state, data, [{:reply, from, {:ok, response}}]}
                  {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
                end

              {:error, _reason} = error ->
                {:keep_state, data, [{:reply, from, error}]}
            end

          :challenging ->
            updated_game = apply_challenging_results(data, turn_state, data.id)

            case Turn.next_phase(data.id) do
              {:ok, _turn} ->
                case build_response(updated_game) do
                  {:ok, response} ->
                    reply = [{:reply, from, {:ok, response}}]

                    case updated_game.status do
                      :finished -> {:next_state, :finished, updated_game, reply}
                      _ -> {:keep_state, updated_game, reply}
                    end

                  {:error, reason} ->
                    {:keep_state, data, [{:reply, from, {:error, reason}}]}
                end

              {:error, _reason} = error ->
                {:keep_state, data, [{:reply, from, error}]}
            end

          :results ->
            case handle_results_phase(data, data.id) do
              {:ok, updated_game} ->
                case build_response(updated_game) do
                  {:ok, response} -> {:keep_state, updated_game, [{:reply, from, {:ok, response}}]}
                  {:error, reason} -> {:keep_state, updated_game, [{:reply, from, {:error, reason}}]}
                end

              {:error, reason} ->
                {:keep_state, data, [{:reply, from, {:error, reason}}]}
            end

          _ ->
            case Turn.next_phase(data.id) do
              {:ok, _turn} ->
                case build_response(data) do
                  {:ok, response} -> {:keep_state, data, [{:reply, from, {:ok, response}}]}
                  {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
                end

              {:error, _reason} = error ->
                {:keep_state, data, [{:reply, from, error}]}
            end
        end
    end
  end

  def in_progress({:call, from}, {:update_timeline, track, user_id, position}, data) do
    Logger.debug("Game #{data.id}: Updating timeline for #{user_id}")

    with {:ok, _turn} <- Turn.update_timeline(data.id, track, user_id, position) do
      case build_response(data) do
        {:ok, response} -> {:keep_state, data, [{:reply, from, {:ok, response}}]}
        {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
      end
    else
      {:error, _reason} = error ->
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def in_progress({:call, from}, :start_playback, data) do
    updated_game = %{data | player: Core.Player.set_playback(data.player, true)}

    case build_response(updated_game) do
      {:ok, response} -> {:keep_state, updated_game, [{:reply, from, {:ok, response}}]}
      {:error, reason} -> {:keep_state, updated_game, [{:reply, from, {:error, reason}}]}
    end
  end

  def in_progress({:call, from}, :pause_playback, data) do
    updated_game = %{data | player: Core.Player.set_playback(data.player, false)}

    case build_response(updated_game) do
      {:ok, response} -> {:keep_state, updated_game, [{:reply, from, {:ok, response}}]}
      {:error, reason} -> {:keep_state, updated_game, [{:reply, from, {:error, reason}}]}
    end
  end

  def in_progress({:call, from}, {:make_assumption, user_id, position}, data) do
    Logger.debug("Game #{data.id}: Making assumption for #{user_id} at #{position}")

    track = data.track

    if is_nil(track) do
      {:keep_state, data, [{:reply, from, {:error, :no_current_track}}]}
    else
      case Turn.update_timeline(data.id, track, user_id, position) do
        {:ok, _turn} ->
          case build_response(data) do
            {:ok, response} -> {:keep_state, data, [{:reply, from, {:ok, response}}]}
            {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
          end

        {:error, _reason} = error ->
          {:keep_state, data, [{:reply, from, error}]}
      end
    end
  end

  def in_progress({:call, from}, {:reorder_timeline, user_id, position}, data) do
    Logger.debug("Game #{data.id}: Reordering timeline for #{user_id} to #{position}")

    case Turn.reorder_timeline(data.id, user_id, position) do
      {:ok, _turn} ->
        case build_response(data) do
          {:ok, response} -> {:keep_state, data, [{:reply, from, {:ok, response}}]}
          {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
        end

      {:error, _reason} = error ->
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def in_progress({:call, from}, {:increment_score, user_id, points}, data) do
    Logger.debug("Game #{data.id}: Incrementing score for #{user_id} by #{points}")

    updated_scores = Map.update(data.scores, user_id, points, &(&1 + points))
    updated_game = %{data | scores: updated_scores}

    with {:winner, winner_uuid} <- check_winner(updated_game) do
      Logger.info("Game #{data.id}: Game won by #{winner_uuid}")

      finished_game = %{updated_game | status: :finished}

      case build_response(finished_game) do
        {:ok, response} ->
          {:next_state, :finished, finished_game, [{:reply, from, {:ok, response}}]}

        {:error, reason} ->
          {:keep_state, finished_game, [{:reply, from, {:error, reason}}]}
      end
    else
      :no_winner ->
        case build_response(updated_game) do
          {:ok, response} -> {:keep_state, updated_game, [{:reply, from, {:ok, response}}]}
          {:error, reason} -> {:keep_state, updated_game, [{:reply, from, {:error, reason}}]}
        end
    end
  end

  def in_progress({:call, from}, :get_state, data) do
    case build_response(data) do
      {:ok, response} -> {:keep_state, data, [{:reply, from, {:ok, response}}]}
      {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
    end
  end

  def in_progress({:call, from}, :get_active_player, %{queue: queue, cursor: cursor} = data) do
    active_player = Enum.at(queue, cursor)
    {:keep_state, data, [{:reply, from, {:ok, active_player}}]}
  end

  def in_progress({:call, from}, {:set_track, track}, data) do
    new_data = %{data | track: track}
    {:keep_state, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def in_progress({:call, from}, :get_track, %{track: track} = data) do
    response = if is_nil(track), do: {:error, :no_current_track}, else: {:ok, track}
    {:keep_state, data, [{:reply, from, response}]}
  end

  def in_progress({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  def in_progress(:info, :next_phase, data) do
    case Turn.get_state(data.id) do
      {:ok, %{phase: :challenging} = turn_state} ->
        updated_game = apply_challenging_results(data, turn_state, data.id)

        case Turn.next_phase(data.id) do
          {:ok, _turn} ->
            case updated_game.status do
              :finished -> {:next_state, :finished, updated_game}
              _ -> {:keep_state, updated_game}
            end

          {:error, _reason} ->
            {:keep_state, data}
        end

      _ ->
        {:keep_state, data}
    end
  end

  # State: :finished (game completed)

  def finished(:enter, _old_state, data) do
    Logger.info("Game #{data.id}: Game finished")
    {:keep_state, data}
  end

  def finished(:info, {:participant_joined, _user_id}, data) do
    {:keep_state, data}
  end

  def finished(:info, {:participant_left, _user_id}, data) do
    {:keep_state, data}
  end

  def finished({:call, from}, :get_state, data) do
    case build_response(data) do
      {:ok, response} -> {:keep_state, data, [{:reply, from, {:ok, response}}]}
      {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
    end
  end

  def finished({:call, from}, :get_active_player, %{queue: queue, cursor: cursor} = data) do
    {:keep_state, data, [{:reply, from, {:ok, Enum.at(queue, cursor)}}]}
  end

  def finished({:call, from}, :get_track, %{track: nil} = data) do
    {:keep_state, data, [{:reply, from, {:error, :no_current_track}}]}
  end

  def finished({:call, from}, :get_track, %{track: track} = data) do
    {:keep_state, data, [{:reply, from, {:ok, track}}]}
  end

  def finished({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :game_finished}}]}
  end

  defp build_response(game) do
    with {:ok, turn_data} <- fetch_turn(game) do
      {:ok, %{game | turn: turn_data}}
    end
  end

  defp fetch_turn(game) do
    case game.status do
      :waiting ->
        {:ok, nil}

      _ ->
        case Turn.get_state(game.id) do
          {:ok, state} -> {:ok, state}
          {:error, :no_turn} -> {:ok, nil}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp handle_presence_joined(data, user_id) do
    user = Core.User.get_user(user_id)

    with :ok <- validate_not_full(data),
         :ok <- validate_not_duplicate(data, user) do
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
    case build_response(game) do
      {:ok, response} ->
        if Process.whereis(Songy.PubSub) do
          Phoenix.PubSub.local_broadcast(
            Songy.PubSub,
            "room:#{game.id}",
            {:game_state_updated, response}
          )
        end

      {:error, _reason} ->
        :ok
    end

    :ok
  end

  defp snapshot_active_user_timeline(game, game_id) do
    active_player = Enum.at(game.queue, game.cursor)

    if is_binary(active_player) do
      timeline = get_user_timeline(game, active_player)
      Turn.set_turn_timeline(game_id, timeline)
      :ok
    else
      :ok
    end
  end

  defp apply_challenging_results(game, turn_state, _game_id) do
    track = game.track

    game =
      case Enum.find(turn_state.assumptions, &valid_assumption?(turn_state.timeline, &1.position)) do
        %{user_id: user_id} ->
          game
          |> increment_user_score_local(user_id, 1)
          |> extend_user_timeline(user_id, track)

        nil ->
          game
      end

    maybe_finish_game(game)
  end

  defp handle_results_phase(game, game_id) do
    with {:ok, provider} <- Songy.Providers.lookup(:providers, game.owner_id),
         {:ok, %Core.Track{} = track} <- Playback.search_random_track(provider),
         {:ok, :playback_paused} <- Playback.pause_playback(provider) do
      new_cursor = rem(game.cursor + 1, max(length(game.queue), 1))

      updated_game = %{
        game
        | player: Core.Player.set_playback(game.player, false),
          track: track,
          cursor: new_cursor
      }

      case Turn.next_phase(game_id) do
        {:ok, _} -> {:ok, updated_game}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp schedule_challenging_timeout do
    timeout = Application.fetch_env!(:songy, :challenging_phase_timeout)
    Process.send_after(self(), :next_phase, timeout)
    :ok
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

  defp maybe_finish_game(game) do
    case check_winner(game) do
      {:winner, _winner_uuid} -> %{game | status: :finished}
      :no_winner -> game
    end
  end

  defp valid_assumption?(timeline, position) do
    case Enum.at(timeline, position) do
      nil ->
        false

      %Core.Track{year: year} ->
        left_neighbor = if position > 0, do: Enum.at(timeline, position - 1), else: nil
        right_neighbor = Enum.at(timeline, position + 1)

        left_valid = is_nil(left_neighbor) or left_neighbor.year <= year
        right_valid = is_nil(right_neighbor) or year <= right_neighbor.year

        left_valid and right_valid
    end
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
    with {winner_uuid, _score} when not is_nil(winner_uuid) <-
           Enum.find(game.scores, fn {_uuid, score} -> score >= game.max_score end) do
      {:winner, winner_uuid}
    else
      nil -> :no_winner
    end
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
