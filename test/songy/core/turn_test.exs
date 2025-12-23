defmodule Songy.Core.TurnTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Turn
  alias Songy.Core.Track

  describe "struct" do
    test "creates a new turn with default values" do
      turn = %Turn{}

      assert turn.phase == nil
      assert turn.timeline == nil
      assert turn.assumptions == nil
    end

    test "creates a new turn with all fields" do
      turn = %Turn{
        phase: :waiting,
        timeline: [],
        assumptions: []
      }

      assert turn.phase == :waiting
      assert turn.timeline == []
      assert turn.assumptions == []
    end
  end

  describe "types" do
    test "has correct type definitions" do
      turn = %Turn{
        phase: :waiting,
        timeline: [],
        assumptions: []
      }

      assert turn.phase in [:waiting, :ready, :steady, :challenging, :results]
      assert is_list(turn.timeline)
      assert is_list(turn.assumptions)
    end
  end

  describe "structure" do
    test "has all required fields" do
      turn = %Turn{
        phase: :waiting,
        timeline: [],
        assumptions: []
      }

      assert %Turn{phase: _, timeline: _, assumptions: _} = turn
    end

    test "can be updated with struct syntax" do
      turn = %Turn{phase: :waiting, timeline: [], assumptions: []}
      track = %Track{id: "1", title: "Song", artist: "Artist", year: 2020}

      updated_turn = %{turn | timeline: [track], phase: :ready}

      assert updated_turn.timeline == [track]
      assert updated_turn.phase == :ready
    end
  end

  describe "phase transitions" do
    test "can be manually updated to different phases" do
      turn = %Turn{phase: :waiting, timeline: [], assumptions: []}

      phases = [:waiting, :ready, :steady, :challenging, :results]

      Enum.each(phases, fn phase ->
        updated_turn = %{turn | phase: phase}
        assert updated_turn.phase == phase
      end)
    end
  end

  describe "timeline management" do
    test "can add tracks to timeline" do
      turn = %Turn{phase: :waiting, timeline: [], assumptions: []}
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
      turn = %Turn{phase: :waiting, timeline: [], assumptions: []}

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
