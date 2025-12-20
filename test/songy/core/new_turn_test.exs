defmodule Songy.Core.NewTurnTest do
  use ExUnit.Case, async: true

  alias Songy.Core.NewTurn
  alias Songy.Core.Track

  describe "struct" do
    test "creates a new turn with default values" do
      turn = %NewTurn{}

      assert turn.game_id == nil
      assert turn.queue == nil
      assert turn.cursor == nil
      assert turn.track == nil
      assert turn.phase == nil
      assert turn.timeline == nil
      assert turn.assumptions == nil
    end

    test "creates a new turn with game ID" do
      turn = %NewTurn{
        game_id: "game-123",
        queue: [],
        cursor: 0,
        phase: :waiting,
        timeline: [],
        assumptions: []
      }

      assert turn.game_id == "game-123"
      assert turn.queue == []
      assert turn.cursor == 0
      assert turn.phase == :waiting
      assert turn.timeline == []
      assert turn.assumptions == []
    end
  end

  describe "types" do
    test "has correct type definitions" do
      turn = %NewTurn{
        game_id: "game-123",
        queue: [],
        cursor: 0,
        phase: :waiting,
        timeline: [],
        assumptions: []
      }

      assert is_binary(turn.game_id)
      assert is_list(turn.queue)
      assert is_integer(turn.cursor)
      assert turn.cursor >= 0
      assert turn.phase in [:waiting, :ready, :steady, :challenging, :results]
      assert is_list(turn.timeline)
      assert is_list(turn.assumptions)
    end
  end

  describe "structure" do
    test "has all required fields" do
      turn = %NewTurn{
        game_id: "game-123",
        queue: [],
        cursor: 0,
        track: nil,
        phase: :waiting,
        timeline: [],
        assumptions: []
      }

      assert %NewTurn{game_id: _, queue: _, cursor: _, track: _, phase: _, timeline: _, assumptions: _} = turn
    end

    test "can be updated with struct syntax" do
      turn = %NewTurn{game_id: "game-123", queue: [], cursor: 0, phase: :waiting, timeline: [], assumptions: []}
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}

      updated_turn = %{turn | track: track, phase: :ready}

      assert updated_turn.track == track
      assert updated_turn.phase == :ready
      assert updated_turn.game_id == turn.game_id
    end
  end

  describe "phase transitions" do
    test "can be manually updated to different phases" do
      turn = %NewTurn{game_id: "game-123", queue: [], cursor: 0, phase: :waiting, timeline: [], assumptions: []}

      phases = [:waiting, :ready, :steady, :challenging, :results]

      Enum.each(phases, fn phase ->
        updated_turn = %{turn | phase: phase}
        assert updated_turn.phase == phase
      end)
    end
  end

  describe "queue management" do
    test "can add players to queue" do
      turn = %NewTurn{game_id: "game-123", queue: [], cursor: 0, phase: :waiting, timeline: [], assumptions: []}

      updated_turn = %{turn | queue: ["player-1", "player-2"]}

      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.cursor == 0
    end

    test "can update cursor" do
      turn = %NewTurn{game_id: "game-123", queue: ["player-1", "player-2", "player-3"], cursor: 0, phase: :waiting, timeline: [], assumptions: []}

      updated_turn = %{turn | cursor: 1}

      assert updated_turn.cursor == 1
      assert Enum.at(updated_turn.queue, updated_turn.cursor) == "player-2"
    end
  end

  describe "timeline management" do
    test "can add tracks to timeline" do
      turn = %NewTurn{game_id: "game-123", queue: [], cursor: 0, phase: :waiting, timeline: [], assumptions: []}
      track1 = %Track{id: "1", title: "Song 1", artist: "Artist 1", year: 2020}
      track2 = %Track{id: "2", title: "Song 2", artist: "Artist 2", year: 2021}

      updated_turn = %{turn | timeline: [track1, track2]}

      assert length(updated_turn.timeline) == 2
      assert Enum.at(updated_turn.timeline, 0) == track1
      assert Enum.at(updated_turn.timeline, 1) == track2
    end
  end

  describe "assumptions management" do
    test "can add assumptions" do
      turn = %NewTurn{game_id: "game-123", queue: [], cursor: 0, phase: :waiting, timeline: [], assumptions: []}

      assumptions = [
        %{position: 0, user_id: "user-1"},
        %{position: 1, user_id: "user-2"}
      ]

      updated_turn = %{turn | assumptions: assumptions}

      assert length(updated_turn.assumptions) == 2
      assert Enum.at(updated_turn.assumptions, 0) == %{position: 0, user_id: "user-1"}
      assert Enum.at(updated_turn.assumptions, 1) == %{position: 1, user_id: "user-2"}
    end
  end
end
