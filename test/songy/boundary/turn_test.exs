defmodule Songy.Boundary.TurnTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Turn
  alias Songy.Core.Turn, as: CoreTurn
  alias Songy.Core.Track

  setup %{test: test} do
    {:ok, _pid} = start_supervised({Turn, id: test})
    %{game_id: test}
  end

  describe "initialization" do
    test "starts in :waiting phase with correct defaults", %{game_id: game_id} do
      {:ok, state} = Turn.get_state(game_id)

      assert state.phase == :waiting
      assert state.timeline == []
      assert state.assumptions == []
    end
  end

  describe ":waiting phase - next_phase" do
    test "transitions to :ready", %{game_id: game_id} do
      assert {:ok, _} = Turn.next_phase(game_id)

      {:ok, state} = Turn.get_state(game_id)
      assert state.phase == :ready
    end
  end

  describe ":waiting phase - set_turn_timeline" do
    test "sets timeline for active user", %{game_id: game_id} do
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      timeline = [track]

      assert {:ok, _} = Turn.set_turn_timeline(game_id, timeline)

      {:ok, state} = Turn.get_state(game_id)
      assert state.timeline == timeline
    end
  end

  describe ":ready phase - operations" do
    setup %{game_id: game_id} do
      Turn.next_phase(game_id)
      :ok
    end

    test "transitions to :steady", %{game_id: game_id} do
      assert {:ok, _} = Turn.next_phase(game_id)

      {:ok, state} = Turn.get_state(game_id)
      assert state.phase == :steady
    end
  end

  describe ":steady phase - operations" do
    setup %{game_id: game_id} do
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      :ok
    end

    test "transitions to :challenging", %{game_id: game_id} do
      assert {:ok, _} = Turn.next_phase(game_id)

      {:ok, state} = Turn.get_state(game_id)
      assert state.phase == :challenging
    end
  end

  describe ":challenging phase - update_timeline" do
    setup %{game_id: game_id} do
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      :ok
    end

    test "adds track to timeline at position 0", %{game_id: game_id} do
      track = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      assert {:ok, _} = Turn.update_timeline(game_id, track, "user-1", 0)

      {:ok, state} = Turn.get_state(game_id)
      assert length(state.timeline) == 1
      assert Enum.at(state.timeline, 0) == track
      assert state.assumptions == [%{position: 0, user_id: "user-1"}]
    end

    test "adds multiple tracks at different positions", %{game_id: game_id} do
      track1 = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      track2 = %Track{id: "3", title: "Song 3", artist: "Artist", year: 2022}

      Turn.update_timeline(game_id, track1, "user-1", 0)
      Turn.update_timeline(game_id, track2, "user-2", 0)

      {:ok, state} = Turn.get_state(game_id)
      assert length(state.timeline) == 2
      assert Enum.at(state.timeline, 0) == track2
      assert Enum.at(state.timeline, 1) == track1
      assert length(state.assumptions) == 2
    end

    test "prevents duplicate tracks in timeline", %{game_id: game_id} do
      track = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}

      Turn.update_timeline(game_id, track, "user-1", 0)
      Turn.update_timeline(game_id, track, "user-2", 1)

      {:ok, state} = Turn.get_state(game_id)
      assert length(state.timeline) == 1
      assert length(state.assumptions) == 1
    end

    test "replaces user's previous assumption", %{game_id: game_id} do
      track1 = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      track2 = %Track{id: "3", title: "Song 3", artist: "Artist", year: 2022}

      Turn.update_timeline(game_id, track1, "user-1", 0)
      Turn.update_timeline(game_id, track2, "user-1", 1)

      {:ok, state} = Turn.get_state(game_id)
      assert length(state.assumptions) == 1
      assert Enum.at(state.assumptions, 0).user_id == "user-1"
      assert Enum.at(state.assumptions, 0).position == 1
    end
  end

  describe ":challenging phase - reorder_timeline" do
    setup %{game_id: game_id} do
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)

      track1 = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      track2 = %Track{id: "3", title: "Song 3", artist: "Artist", year: 2022}
      Turn.update_timeline(game_id, track1, "user-1", 0)
      Turn.update_timeline(game_id, track2, "user-2", 0)

      :ok
    end

    test "moves track to new position", %{game_id: game_id} do
      assert {:ok, _} = Turn.reorder_timeline(game_id, "user-1", 0)

      {:ok, state} = Turn.get_state(game_id)
      assert Enum.at(state.timeline, 0).id == "2"
      assert Enum.at(state.assumptions, 0).user_id == "user-1"
      assert Enum.at(state.assumptions, 0).position == 0
    end

    test "returns error if user has no assumption", %{game_id: game_id} do
      assert {:error, :user_assumption_not_found} = Turn.reorder_timeline(game_id, "user-3", 0)
    end

    test "updates other assumptions when moving", %{game_id: game_id} do
      Turn.reorder_timeline(game_id, "user-1", 0)

      {:ok, state} = Turn.get_state(game_id)
      user2_assumption = Enum.find(state.assumptions, &(&1.user_id == "user-2"))
      assert user2_assumption.position == 1
    end
  end

  describe ":challenging phase - next_phase" do
    setup %{game_id: game_id} do
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      :ok
    end

    test "transitions to :results", %{game_id: game_id} do
      assert {:ok, _} = Turn.next_phase(game_id)

      {:ok, state} = Turn.get_state(game_id)
      assert state.phase == :results
    end
  end

  describe ":results phase - next_phase" do
    setup %{game_id: game_id} do
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      :ok
    end

    test "transitions back to :waiting and clears state", %{game_id: game_id} do
      assert {:ok, _} = Turn.next_phase(game_id)

      {:ok, state} = Turn.get_state(game_id)
      assert state.phase == :waiting
      assert state.timeline == []
      assert state.assumptions == []
    end
  end

  describe "get_state" do
    test "returns complete state", %{game_id: game_id} do
      {:ok, state} = Turn.get_state(game_id)

      assert %CoreTurn{} = state
      assert state.phase == :waiting
      assert state.timeline == []
      assert state.assumptions == []
    end
  end

  describe "phase transitions" do
    test "completes full turn cycle", %{game_id: game_id} do
      assert {:ok, _} = Turn.next_phase(game_id)
      {:ok, state} = Turn.get_state(game_id)
      assert state.phase == :ready

      assert {:ok, _} = Turn.next_phase(game_id)
      {:ok, state} = Turn.get_state(game_id)
      assert state.phase == :steady

      assert {:ok, _} = Turn.next_phase(game_id)
      {:ok, state} = Turn.get_state(game_id)
      assert state.phase == :challenging

      assert {:ok, _} = Turn.next_phase(game_id)
      {:ok, state} = Turn.get_state(game_id)
      assert state.phase == :results

      assert {:ok, _} = Turn.next_phase(game_id)
      {:ok, state} = Turn.get_state(game_id)
      assert state.phase == :waiting
    end
  end

  describe "timeline and assumptions" do
    setup %{game_id: game_id} do
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      Turn.next_phase(game_id)
      :ok
    end

    test "maintains timeline and assumptions through phases", %{game_id: game_id} do
      track1 = %Track{id: "1", title: "Song 1", artist: "Artist 1", year: 2020}
      track2 = %Track{id: "2", title: "Song 2", artist: "Artist 2", year: 2021}

      Turn.update_timeline(game_id, track1, "user-1", 0)
      Turn.update_timeline(game_id, track2, "user-2", 0)

      {:ok, state} = Turn.get_state(game_id)
      assert length(state.timeline) == 2
      assert length(state.assumptions) == 2

      # Transition to results
      Turn.next_phase(game_id)

      # Transition back to waiting should reset
      Turn.next_phase(game_id)

      {:ok, state} = Turn.get_state(game_id)
      assert state.timeline == []
      assert state.assumptions == []
    end
  end
end
