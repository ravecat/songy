defmodule Songy.Boundary.TurnTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Turn
  alias Songy.Core.NewTurn
  alias Songy.Core.Track

  setup %{test: test} do
    {:ok, pid} = start_supervised({Turn, game_id: test})
    %{pid: pid}
  end

  describe "initialization" do
    test "starts in :waiting phase with correct defaults", %{pid: pid} do
      state = Turn.get_state(pid)

      assert state.phase == :waiting
      assert state.queue == []
      assert state.cursor == 0
      assert state.track == nil
      assert state.timeline == []
      assert state.assumptions == []
    end
  end

  describe ":waiting phase - add_player" do
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
  end

  describe ":waiting phase - next_phase" do
    test "transitions to :ready when players exist", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      assert :ok = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :ready
    end

    test "fails to transition if no players", %{pid: pid} do
      assert {:error, :no_players} = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :waiting
    end
  end

  describe ":waiting phase - get_active_player" do
    test "returns nil for empty queue", %{pid: pid} do
      assert {:ok, nil} = Turn.get_active_player(pid)
    end

    test "returns first player when players exist", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.add_player(pid, "player-2")

      assert {:ok, "player-1"} = Turn.get_active_player(pid)
    end
  end

  describe ":waiting phase - remove_player" do
    test "removes player from queue", %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.add_player(pid, "player-2")

      assert :ok = Turn.remove_player(pid, "player-1")

      state = Turn.get_state(pid)
      assert state.queue == ["player-2"]
    end

    test "does nothing if player not found", %{pid: pid} do
      Turn.add_player(pid, "player-1")

      assert :ok = Turn.remove_player(pid, "player-2")

      state = Turn.get_state(pid)
      assert state.queue == ["player-1"]
    end
  end

  describe ":waiting phase - invalid actions" do
    test "rejects set_track", %{pid: pid} do
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      assert {:error, :invalid_action} = Turn.set_track(pid, track)
    end

    test "rejects update_timeline", %{pid: pid} do
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      assert {:error, :invalid_action} = Turn.update_timeline(pid, track, "user-1", 0)
    end

    test "rejects reorder_timeline", %{pid: pid} do
      assert {:error, :invalid_action} = Turn.reorder_timeline(pid, "user-1", 0)
    end
  end

  describe ":ready phase - operations" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      :ok
    end

    test "can set track", %{pid: pid} do
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      assert :ok = Turn.set_track(pid, track)

      state = Turn.get_state(pid)
      assert state.track == track
    end

    test "get_track returns the set track", %{pid: pid} do
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)

      assert {:ok, ^track} = Turn.get_track(pid)
    end
  end

  describe ":ready phase - next_phase" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      :ok
    end

    test "transitions to :steady when track is set", %{pid: pid} do
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      assert :ok = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :steady
    end

    test "fails to transition if no track", %{pid: pid} do
      assert {:error, :no_track} = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :ready
    end
  end

  describe ":ready phase - invalid actions" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      :ok
    end

    test "rejects add_player", %{pid: pid} do
      assert {:error, :invalid_action} = Turn.add_player(pid, "player-2")
    end

    test "rejects update_timeline", %{pid: pid} do
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      assert {:error, :invalid_action} = Turn.update_timeline(pid, track, "user-1", 0)
    end

    test "rejects reorder_timeline", %{pid: pid} do
      assert {:error, :invalid_action} = Turn.reorder_timeline(pid, "user-1", 0)
    end
  end

  describe ":steady phase - operations" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)

      :ok
    end

    test "transitions to :challenging", %{pid: pid} do
      assert :ok = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :challenging
    end
  end

  describe ":steady phase - invalid actions" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)

      :ok
    end

    test "rejects add_player", %{pid: pid} do
      assert {:error, :invalid_action} = Turn.add_player(pid, "player-2")
    end

    test "rejects set_track", %{pid: pid} do
      track = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      assert {:error, :invalid_action} = Turn.set_track(pid, track)
    end

    test "rejects update_timeline", %{pid: pid} do
      track = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      assert {:error, :invalid_action} = Turn.update_timeline(pid, track, "user-1", 0)
    end

    test "rejects reorder_timeline", %{pid: pid} do
      assert {:error, :invalid_action} = Turn.reorder_timeline(pid, "user-1", 0)
    end
  end

  describe ":challenging phase - update_timeline" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      :ok
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
  end

  describe ":challenging phase - reorder_timeline" do
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

      :ok
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
  end

  describe ":challenging phase - next_phase" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      :ok
    end

    test "transitions to :results", %{pid: pid} do
      assert :ok = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :results
    end
  end

  describe ":challenging phase - invalid actions" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      :ok
    end

    test "rejects add_player", %{pid: pid} do
      assert {:error, :invalid_action} = Turn.add_player(pid, "player-2")
    end

    test "rejects set_track", %{pid: pid} do
      track = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      assert {:error, :invalid_action} = Turn.set_track(pid, track)
    end
  end

  describe ":results phase - next_phase" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.add_player(pid, "player-2")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      :ok
    end

    test "transitions to :waiting and advances cursor", %{pid: pid} do
      assert :ok = Turn.next_phase(pid)

      state = Turn.get_state(pid)
      assert state.phase == :waiting
      assert state.cursor == 1
      assert state.track == nil
      assert state.timeline == []
      assert state.assumptions == []
    end

    test "updates active player after cursor advance", %{pid: pid} do
      Turn.next_phase(pid)

      assert {:ok, "player-2"} = Turn.get_active_player(pid)
    end
  end

  describe ":results phase - invalid actions" do
    setup %{pid: pid} do
      Turn.add_player(pid, "player-1")
      Turn.next_phase(pid)

      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}
      Turn.set_track(pid, track)
      Turn.next_phase(pid)
      Turn.next_phase(pid)
      Turn.next_phase(pid)

      :ok
    end

    test "rejects add_player", %{pid: pid} do
      assert {:error, :invalid_action} = Turn.add_player(pid, "player-2")
    end

    test "rejects set_track", %{pid: pid} do
      track = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      assert {:error, :invalid_action} = Turn.set_track(pid, track)
    end

    test "rejects update_timeline", %{pid: pid} do
      track = %Track{id: "2", title: "Song 2", artist: "Artist", year: 2021}
      assert {:error, :invalid_action} = Turn.update_timeline(pid, track, "user-1", 0)
    end

    test "rejects reorder_timeline", %{pid: pid} do
      assert {:error, :invalid_action} = Turn.reorder_timeline(pid, "user-1", 0)
    end
  end

  describe "remove_player - cursor adjustment" do
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
  end

  describe "get_state" do
    test "returns complete state", %{pid: pid} do
      state = Turn.get_state(pid)

      assert %NewTurn{} = state
      assert state.phase == :waiting
      assert state.queue == []
      assert state.cursor == 0
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
