defmodule Songy.Boundary.Turn do
  @moduledoc """
  Turn process managing game turn state using GenStateMachine.
  """

  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  alias Songy.Core

  def child_spec(opts) do
    game_id = Keyword.fetch!(opts, :id)

    %{
      id: {__MODULE__, game_id},
      start: {__MODULE__, :start_link, [opts]},
      restart: :temporary
    }
  end

  @doc "Starts a turn process for the given game."
  def start_link(opts) when is_list(opts) do
    game_id = Keyword.fetch!(opts, :id)

    GenStateMachine.start_link(__MODULE__, opts, name: via(game_id))
  end

  @doc "Looks up the turn process PID for a game."
  def lookup_turn_process(game_id) do
    case Registry.lookup(Songy.Registry, {:turn, game_id}) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  @doc "Advances to the next phase."
  def next_phase(game_id, timeout \\ 1_000) do
    call_if_exists(game_id, :next_phase, timeout)
  end

  @doc "Snapshots the active player's timeline for this turn."
  def set_turn_timeline(game_id, timeline, timeout \\ 1_000) when is_list(timeline) do
    call_if_exists(game_id, {:set_turn_timeline, timeline}, timeout)
  end

  @doc "Updates the timeline with a track at the specified position."
  def update_timeline(game_id, track, user_id, position \\ 0, timeout \\ 1_000) do
    call_if_exists(game_id, {:update_timeline, track, user_id, position}, timeout)
  end

  @doc "Reorders the timeline by moving a user's track to a new position."
  def reorder_timeline(game_id, user_id, new_position, timeout \\ 1_000) do
    call_if_exists(game_id, {:reorder_timeline, user_id, new_position}, timeout)
  end

  @doc "Gets the current turn state."
  def get_state(game_id, timeout \\ 1_000) do
    call_if_exists(game_id, :get_state, timeout)
  end

  # Callbacks

  def init(opts) do
    _game_id = Keyword.fetch!(opts, :id)

    {:ok, :waiting,
     %Core.Turn{
       phase: :waiting,
       timeline: [],
       assumptions: []
     }}
  end

  defp via(game_id) do
    {:via, Registry, {Songy.Registry, {:turn, game_id}}}
  end

  defp call_if_exists(game_id, message, timeout) do
    case lookup_turn_process(game_id) do
      nil -> {:error, :no_turn}
      pid -> GenStateMachine.call(pid, message, timeout)
    end
  rescue
    _ -> {:error, :no_turn}
  catch
    _, _ -> {:error, :no_turn}
  end

  # State: :waiting
  def waiting(:enter, _old_state, data), do: {:keep_state, data}

  def waiting({:call, from}, {:set_turn_timeline, timeline}, data) do
    new_data = %{data | timeline: timeline}
    {:keep_state, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def waiting({:call, from}, :next_phase, data) do
    new_data = %{data | phase: :ready}
    {:next_state, :ready, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def waiting({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, {:ok, data}}]}
  end

  def waiting({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :ready
  def ready(:enter, _old_state, data), do: {:keep_state, data}

  def ready({:call, from}, :next_phase, data) do
    new_data = %{data | phase: :steady}
    {:next_state, :steady, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def ready({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, {:ok, data}}]}
  end

  def ready({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :steady
  def steady(:enter, _old_state, data), do: {:keep_state, data}

  def steady({:call, from}, :next_phase, data) do
    new_data = %{data | phase: :challenging}
    {:next_state, :challenging, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def steady({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, {:ok, data}}]}
  end

  def steady({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :challenging
  def challenging(:enter, _old_state, data), do: {:keep_state, data}

  def challenging({:call, from}, {:update_timeline, track, user, pos}, data) do
    new_data = update_timeline_logic(data, track, user, pos)
    {:keep_state, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def challenging({:call, from}, {:reorder_timeline, user, new_pos}, data) do
    case reorder_timeline_logic(data, user, new_pos) do
      {:ok, new_data} -> {:keep_state, new_data, [{:reply, from, {:ok, new_data}}]}
      {:error, reason} -> {:keep_state, data, [{:reply, from, {:error, reason}}]}
    end
  end

  def challenging({:call, from}, :next_phase, data) do
    new_data = %{data | phase: :results}
    {:next_state, :results, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def challenging({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, {:ok, data}}]}
  end

  def challenging({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  # State: :results
  def results(:enter, _old_state, data), do: {:keep_state, data}

  def results({:call, from}, :next_phase, data) do
    new_data = reset_for_next_player(data)
    {:next_state, :waiting, new_data, [{:reply, from, {:ok, new_data}}]}
  end

  def results({:call, from}, :get_state, data) do
    {:keep_state, data, [{:reply, from, {:ok, data}}]}
  end

  def results({:call, from}, _event, data) do
    {:keep_state, data, [{:reply, from, {:error, :invalid_action}}]}
  end

  defp update_timeline_logic(data, track, user_id, position) do
    case Enum.find_index(data.timeline, fn t -> t.id == track.id end) do
      nil ->
        {before, after_items} = Enum.split(data.timeline, position)
        new_timeline = before ++ [track] ++ after_items

        new_assumptions =
          data.assumptions
          |> Enum.reject(&(&1.user_id == user_id))
          |> Enum.map(fn
            %{position: pos} = assumption when pos >= position ->
              %{assumption | position: pos + 1}

            assumption ->
              assumption
          end)
          |> Enum.concat([%{position: position, user_id: user_id}])

        %{data | timeline: new_timeline, assumptions: new_assumptions}

      _index ->
        data
    end
  end

  defp reorder_timeline_logic(data, user_id, new_position) do
    case Enum.find_index(data.assumptions, fn %{user_id: uid} -> uid == user_id end) do
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

  defp reset_for_next_player(_data) do
    %Core.Turn{
      phase: :waiting,
      timeline: [],
      assumptions: []
    }
  end
end
