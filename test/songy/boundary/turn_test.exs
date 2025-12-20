defmodule Songy.Boundary.TurnTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Turn
  alias Songy.Core.NewTurn
  alias Songy.Core.Track

  setup do
    {:ok, pid} = Turn.start_link("game-123")
    %{pid: pid}
  end

  describe "start_link/2" do
    test "starts a turn process with game ID" do
      {:ok, pid} = Turn.start_link("game-456")
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "initializes with waiting phase" do
      {:ok, pid} = Turn.start_link("game-789")
      state = Turn.get_state(pid)
      assert state.phase == :waiting
      assert state.game_id == "game-789"
    end
  end

  describe "add_player/2" do
    test "adds a player to the queue", %{pid: pid} do
      assert :ok = Turn.add_player(pid, "player-1")
      state = Turn.get_state(pid)
      assert state.queue == ["player-1"]
    end

    test "adds multiple players to the queue", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.add_player(pid, "player-2")
      Turn.add_player(pid, "player-3")

      state = Turn.get_state(pid)
      assert state.queue == ["player-1", "player-2", "player-3"]
    end

    test "only works in waiting phase", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      assert {:error, :invalid_action} = Turn.add_player(pid, "player-2")
    end
  end

  describe "next_phase/1" do
    test "transitions from waiting to ready", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      assert :ok = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :ready
    end

    test "fails to transition from waiting if no players", %{pid: pid} do
      assert {:error, :no_players} = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :waiting
    end

    test "transitions from ready to steady", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      assert :ok = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :steady
    end

    test "fails to transition from ready if no track", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      assert {:error, :no_track} = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :ready
    end

    test "transitions from steady to challenging", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)

      assert :ok = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :challenging
    end

    test "transitions from challenging to results", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      assert :ok = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :results
    end

    test "transitions from results to waiting and advances cursor", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.add_player(pid, "player-2")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      assert :ok = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :waiting
      assert state.cursor == 1
      assert state.track == nil
      assert state.timeline == []
      assert state.assumptions == []
    end
  end

  describe "set_track/2" do
    test "sets the track in ready phase", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      assert :ok = Turn.set_track(pid, track)

      state = Turn.get_state(pid)
      assert state.track == track
    end

    test "only works in ready phase", %{pid: pid} do
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      assert {:error, :invalid_action} = Turn.set_track(pid, track)
    end
  end

  describe "update_timeline/4" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      %{pid: pid}
    end

    test "adds track to timeline at position 0", %{pid: pid} do
      track = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      assert :ok = Turn.update_timeline(pid, track, "user-1", 0)

      state = Turn.get_state(pid)
      assert length(state.timeline) == 1
      assert Enum.at(state.timeline, 0) == track
      assert state.assumptions == [%{position: 0, user_id: "user-1"}]
    end

    test "adds multiple tracks at different positions", %{pid: pid} do
      track1 = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      track2 = %Track{id: "3", title: "Song 3", artist: "Artist", year: 2022}

      Turn.update_timeline(pid, track1, "user-1", 0)
      Turn.update_timeline(pid, track2, "user-2", 0)

      state = Turn.get_state(pid)
      assert length(state.timeline) == 2
      assert Enum.at(state.timeline, 0) == track2
      assert Enum.at(state.timeline, 1) == track1
      assert length(state.assumptions) == 2
    end

    test "prevents duplicate tracks in timeline", %{pid: pid} do
      track = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}

      Turn.update_timeline(pid, track, "user-1", 0)
      Turn.update_timeline(pid, track, "user-2", 1)

      state = Turn.get_state(pid)
      assert length(state.timeline) == 1
      assert length(state.assumptions) == 1
    end

    test "replaces user's previous assumption", %{pid: pid} do
      track1 = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      track2 = %Track{id: "3", title: "Song 3", artist: "Artist", year: 2022}

      Turn.update_timeline(pid, track1, "user-1", 0)
      Turn.update_timeline(pid, track2, "user-1", 1)

      state = Turn.get_state(pid)
      assert length(state.assumptions) == 1
      assert Enum.at(state.assumptions, 0).user_id == "user-1"
      assert Enum.at(state.assumptions, 0).position == 1
    end

    test "only works in challenging phase", %{pid: pid} do
      Turn.next_phase(pid)

      track = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      assert {:error, :invalid_action} = Turn.update_timeline(pid, track, "user-1", 0)
    end
  end

  describe "reorder_timeline/3" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      track1 = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      track2 = %Track{id: "3", title: "Song 3", artist: "Artist", year: 2022}
      Turn.update_timeline(pid, track1, "user-1", 0)
      Turn.update_timeline(pid, track2, "user-2", 0)

      %{pid: pid}
    end

    test "moves track to new position", %{pid: pid} do
      assert :ok = Turn.reorder_timeline(pid, "user-1", 0)

      state = Turn.get_state(pid)
      assert Enum.at(state.timeline, 0).id == "2"
      assert Enum.at(state.assumptions, 0).user_id == "user-1"
      assert Enum.at(state.assumptions, 0).position == 0
    end

    test "returns error if user has no assumption", %{pid: pid} do
      assert {:error, :user_assumption_not_found} = Turn.reorder_timeline(pid, "user-3", 0)
    end

    test "updates other assumptions when moving", %{pid: pid} do
      Turn.reorder_timeline(pid, "user-1", 0)

      state = Turn.get_state(pid)
      user2_assumption = Enum.find(state.assumptions, &(&1.user_id == "user-2"))
      assert user2_assumption.position == 1
    end

    test "only works in challenging phase", %{pid: pid} do
      Turn.next_phase(pid)

      assert {:error, :invalid_action} = Turn.reorder_timeline(pid, "user-1", 0)
    end
  end

  describe "get_active_player/1" do
    test "returns nil for empty queue", %{pid: pid} do
      assert {:ok, nil} = Turn.get_active_player(pid)
    end

    test "returns first player initially", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.add_player(pid, "player-2")

      assert {:ok, "player-1"} = Turn.get_active_player(pid)
    end

    test "returns next player after cursor advance", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.add_player(pid, "player-2")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      assert {:ok, "player-2"} = Turn.get_active_player(pid)
    end
  end

  describe "remove_player/2" do
    test "removes player from queue", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.add_player(pid, "player-2")

      assert :ok = Turn.remove_player(pid, "player-1")

      state = Turn.get_state(pid)
      assert state.queue == ["player-2"]
    end

    test "adjusts cursor when removing player before cursor", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.add_player(pid, "player-2")
      Turn.add_player(pid, "player-3")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.cursor == 1

      Turn.remove_player(pid, "player-1")

      state = Turn.get_state(pid)
      assert state.cursor == 0
      assert {:ok, "player-2"} = Turn.get_active_player(pid)
    end

    test "does nothing if player not found", %{pid: pid} do
      Turn.add_player(pid, "player-1")

      assert :ok = Turn.remove_player(pid, "player-2")

      state = Turn.get_state(pid)
      assert state.queue == ["player-1"]
    end
  end

  describe "get_track/1" do
    test "returns nil initially", %{pid: pid} do
      assert {:ok, nil} = Turn.get_track(pid)
    end

    test "returns track after set", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)

      assert {:ok, ^track} = Turn.get_track(pid)
    end
  end

  describe "get_state/1" do
    test "returns complete state", %{pid: pid} do
      state = Turn.get_state(pid)

      assert %NewTurn{} = state
      assert state.game_id == "game-123"
      assert state.phase == :waiting
      assert state.queue == []
      assert state.cursor == 0
    end
  end

  describe "state machine validation" do
    test "prevents invalid transitions", %{pid: pid} do
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}

      assert {:error, :invalid_action} = Turn.set_track(pid, track)
      assert {:error, :invalid_action} = Turn.update_timeline(pid, track, "user-1", 0)
      assert {:error, :invalid_action} = Turn.reorder_timeline(pid, "user-1", 0)
    end

    test "allows valid operations in each phase", %{pid: pid} do
      # waiting phase
      assert :ok = Turn.add_player(pid, "player-1")

      # ready phase
      Turn.next_phase(pid)
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      assert :ok = Turn.set_track(pid, track)

      # steady phase
      Turn.next_phase(pid)
      assert :ok = Turn.next_phase(pid)

      # challenging phase
      track2 = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      assert :ok = Turn.update_timeline(pid, track2, "user-1", 0)
      assert :ok = Turn.reorder_timeline(pid, "user-1", 0)
    end
  end

  describe "full turn cycle" do
    test "completes full turn cycle with multiple players", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.add_player(pid, "player-2")
      Turn.add_player(pid, "player-3")

      assert {:ok, "player-1"} = Turn.get_active_player(pid)

      Turn.next_phase(pid)
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      track2 = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      Turn.update_timeline(pid, track2, "user-1", 0)
      Turn.next_phase(pid)

      Turn.next_phase(pid)
      state = Turn.get_state(pid)
      assert state.phase == :waiting
      assert {:ok, "player-2"} = Turn.get_active_player(pid)

      Turn.next_phase(pid)
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      assert {:ok, "player-3"} = Turn.get_active_player(pid)
    end
  end
end
