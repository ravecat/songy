defmodule Songy.Boundary.Turn do
  @moduledoc """
  Turn process managing game turn state using GenStateMachine.
  """

  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  alias Songy.Core.NewTurn

  @doc "Starts a turn process for the given game."
  def start_link(game_id, opts \\ []) do
    GenStateMachine.start_link(__MODULE__, game_id, opts)
  end

  @doc "Adds a player to the queue."
  def add_player(pid, player_uuid) do
    GenStateMachine.call(pid, {:add_player, player_uuid})
  end

  @doc "Advances to the next phase."
  def next_phase(pid) do
    GenStateMachine.call(pid, :next_phase)
  end

  @doc "Sets the current track."
  def set_track(pid, track) do
    GenStateMachine.call(pid, {:set_track, track})
  end

  @doc "Updates the timeline with a track at the specified position."
  def update_timeline(pid, track, user_uuid, position \\ 0) do
    GenStateMachine.call(pid, {:update_timeline, track, user_uuid, position})
  end

  @doc "Reorders the timeline by moving a user's track to a new position."
  def reorder_timeline(pid, user_uuid, new_position) do
    GenStateMachine.call(pid, {:reorder_timeline, user_uuid, new_position})
  end

  @doc "Gets the current turn state."
  def get_state(pid) do
    GenStateMachine.call(pid, :get_state)
  end

  @doc "Gets the active player UUID from the queue."
  def get_active_player(pid) do
    GenStateMachine.call(pid, :get_active_player)
  end

  @doc "Removes a player from the queue."
  def remove_player(pid, player_uuid) do
    GenStateMachine.call(pid, {:remove_player, player_uuid})
  end

  @doc "Gets the current track."
  def get_track(pid) do
    GenStateMachine.call(pid, :get_track)
  end

  # Callbacks

  def init(_game_id) do
    {:ok, :waiting,
     %NewTurn{
       queue: [],
       cursor: 0,
       track: nil,
       phase: :waiting,
       timeline: [],
       assumptions: []
     }}
  end

  # State: :waiting
  def waiting(:enter, _old_state, data), do: {:keep_state, data}

  def waiting({:call, from}, {:add_player, player}, data) do
    new_data = %{data | queue: data.queue ++ [player]}
    {:keep_state, new_data, [{:reply, from, :ok}]}
  end

  def waiting({:call, from}, :next_phase, %{queue: []} = data) do
    {:keep_state, data, [{:reply, from, {:error, :no_players}}]}
  end

  def waiting({:call, from}, :next_phase, data) do
    {:next_state, :ready, %{data | phase: :ready}, [{:reply, from, :ok}]}
  end

  def waiting({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, data}]}
  end

  def waiting({:call, from}, :get_active_player, %{queue: queue, cursor: cursor} = data) do
    active_player = Enum.at(queue, cursor)
    {:keep_state, data, [{:reply, from, {:ok, active_player}}]}
  end

  def waiting({:call, from}, {:remove_player, player_uuid}, data) do
    new_data = do_remove_player(data, player_uuid)
    {:keep_state, new_data, [{:reply, from, :ok}]}
  end

  def waiting({:call, from}, :get_track, %{track: track} = data) do
    {:keep_state, data, [{:reply, from, {:ok, track}}]}
  end

  def waiting({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :ready
  def ready(:enter, _old_state, data), do: {:keep_state, data}

  def ready({:call, from}, {:set_track, track}, data) do
    {:keep_state, %{data | track: track}, [{:reply, from, :ok}]}
  end

  def ready({:call, from}, :next_phase, %{track: nil} = data) do
    {:keep_state, data, [{:reply, from, {:error, :no_track}}]}
  end

  def ready({:call, from}, :next_phase, data) do
    {:next_state, :steady, %{data | phase: :steady}, [{:reply, from, :ok}]}
  end

  def ready({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, data}]}
  end

  def ready({:call, from}, :get_active_player, %{queue: queue, cursor: cursor} = data) do
    active_player = Enum.at(queue, cursor)
    {:keep_state, data, [{:reply, from, {:ok, active_player}}]}
  end

  def ready({:call, from}, {:remove_player, player_uuid}, data) do
    new_data = do_remove_player(data, player_uuid)
    {:keep_state, new_data, [{:reply, from, :ok}]}
  end

  def ready({:call, from}, :get_track, %{track: track} = data) do
    {:keep_state, data, [{:reply, from, {:ok, track}}]}
  end

  def ready({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :steady
  def steady(:enter, _old_state, data) do
    timeline = get_player_timeline(data)
    {:keep_state, %{data | timeline: timeline}}
  end

  def steady({:call, from}, :next_phase, data) do
    {:next_state, :challenging, %{data | phase: :challenging}, [{:reply, from, :ok}]}
  end

  def steady({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, data}]}
  end

  def steady({:call, from}, :get_active_player, %{queue: queue, cursor: cursor} = data) do
    active_player = Enum.at(queue, cursor)
    {:keep_state, data, [{:reply, from, {:ok, active_player}}]}
  end

  def steady({:call, from}, {:remove_player, player_uuid}, data) do
    new_data = do_remove_player(data, player_uuid)
    {:keep_state, new_data, [{:reply, from, :ok}]}
  end

  def steady({:call, from}, :get_track, %{track: track} = data) do
    {:keep_state, data, [{:reply, from, {:ok, track}}]}
  end

  def steady({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :challenging
  def challenging(:enter, _old_state, data), do: {:keep_state, data}

  def challenging({:call, from}, {:update_timeline, track, user, pos}, data) do
    new_data = update_timeline_logic(data, track, user, pos)
    {:keep_state, new_data, [{:reply, from, :ok}]}
  end

  def challenging({:call, from}, {:reorder_timeline, user, new_pos}, data) do
    case reorder_timeline_logic(data, user, new_pos) do
      {:ok, new_data} -> {:keep_state, new_data, [{:reply, from, :ok}]}
      {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
    end
  end

  def challenging({:call, from}, :next_phase, data) do
    {:next_state, :results, %{data | phase: :results}, [{:reply, from, :ok}]}
  end

  def challenging({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, data}]}
  end

  def challenging({:call, from}, :get_active_player, %{queue: queue, cursor: cursor} = data) do
    active_player = Enum.at(queue, cursor)
    {:keep_state, data, [{:reply, from, {:ok, active_player}}]}
  end

  def challenging({:call, from}, {:remove_player, player_uuid}, data) do
    new_data = do_remove_player(data, player_uuid)
    {:keep_state, new_data, [{:reply, from, :ok}]}
  end

  def challenging({:call, from}, :get_track, %{track: track} = data) do
    {:keep_state, data, [{:reply, from, {:ok, track}}]}
  end

  def challenging({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :results
  def results(:enter, _old_state, data), do: {:keep_state, data}

  def results({:call, from}, :next_phase, data) do
    new_data = reset_for_next_player(data)
    {:next_state, :waiting, %{new_data | phase: :waiting}, [{:reply, from, :ok}]}
  end

  def results({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, data}]}
  end

  def results({:call, from}, :get_active_player, %{queue: queue, cursor: cursor} = data) do
    active_player = Enum.at(queue, cursor)
    {:keep_state, data, [{:reply, from, {:ok, active_player}}]}
  end

  def results({:call, from}, {:remove_player, player_uuid}, data) do
    new_data = do_remove_player(data, player_uuid)
    {:keep_state, new_data, [{:reply, from, :ok}]}
  end

  def results({:call, from}, :get_track, %{track: track} = data) do
    {:keep_state, data, [{:reply, from, {:ok, track}}]}
  end

  def results({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  defp get_player_timeline(%{queue: _queue, cursor: _cursor}) do
    []
  end

  defp update_timeline_logic(data, track, user_uuid, position) do
    case Enum.find_index(data.timeline, fn t -> t.id == track.id end) do
      nil ->
        {before, after_items} = Enum.split(data.timeline, position)
        new_timeline = before ++ [track] ++ after_items

        new_assumptions =
          data.assumptions
          |> Enum.reject(&(&1.user_id == user_uuid))
          |> Enum.map(fn
            %{position: pos} = assumption when pos >= position ->
              %{assumption | position: pos + 1}

            assumption ->
              assumption
          end)
          |> Enum.concat([%{position: position, user_id: user_uuid}])

        %{data | timeline: new_timeline, assumptions: new_assumptions}

      _index ->
        data
    end
  end

  defp reorder_timeline_logic(data, user_uuid, new_position) do
    case Enum.find_index(data.assumptions, fn %{user_id: uid} -> uid == user_uuid end) do
      nil ->
        {:error, :user_assumption_not_found}

      index ->
        assumption = Enum.at(data.assumptions, index)
        old_position = assumption.position

        if old_position == new_position do
          {:ok, data}
        else
          track = Enum.at(data.timeline, old_position)
          new_timeline = List.delete_at(data.timeline, old_position)
          {before, after_items} = Enum.split(new_timeline, new_position)
          new_timeline = before ++ [track] ++ after_items

          new_assumptions =
            Enum.map(data.assumptions, fn
              %{position: pos} = assumption when pos == old_position ->
                %{assumption | position: new_position}

              %{position: pos} = assumption when old_position < pos and pos <= new_position ->
                %{assumption | position: pos - 1}

              %{position: pos} = assumption when new_position <= pos and pos < old_position ->
                %{assumption | position: pos + 1}

              assumption ->
                assumption
            end)

          {:ok, %{data | timeline: new_timeline, assumptions: new_assumptions}}
        end
    end
  end

  defp reset_for_next_player(data) do
    new_cursor = rem(data.cursor + 1, max(length(data.queue), 1))

    %NewTurn{
      queue: data.queue,
      cursor: new_cursor,
      track: nil,
      phase: :waiting,
      timeline: [],
      assumptions: []
    }
  end

  defp do_remove_player(%{queue: queue} = data, player_uuid) do
    case Enum.find_index(queue, &(&1 == player_uuid)) do
      nil ->
        data

      player_index ->
        new_queue = List.delete_at(queue, player_index)

        new_index =
          cond do
            player_index < data.cursor -> data.cursor - 1
            player_index == data.cursor -> data.cursor
            player_index > data.cursor -> data.cursor
          end

        adjusted_index =
          if length(new_queue) > 0 do
            rem(new_index, length(new_queue))
          else
            0
          end

        %{data | queue: new_queue, cursor: adjusted_index}
    end
  end
end
