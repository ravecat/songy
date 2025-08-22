defmodule Songy.Core.TurnTest do
  use ExUnit.Case, async: true

  alias Songy.Core.{Turn, Track}

  describe "new/0" do
    test "creates turn with default values" do
      turn = Turn.new()

      assert %Turn{} = turn
      assert turn.queue == []
      assert turn.cursor == 0
      assert turn.track == nil
      assert turn.phase == :waiting
    end
  end

  describe "get_active_player/1" do
    test "returns the current player from the queue" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # results -> waiting (advances to next player)
        |> Turn.next_phase()

      assert Turn.get_active_player(turn) == "player-2"
    end

    test "returns first player when cursor is 0" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")

      assert Turn.get_active_player(turn) == "player-1"
    end

    test "returns last player when cursor points to last element" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting (advances to player-2)
        |> Turn.next_phase()
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting (advances to player-3)
        |> Turn.next_phase()

      assert Turn.get_active_player(turn) == "player-3"
    end

    test "returns nil when queue is empty" do
      turn = Turn.new()
      assert Turn.get_active_player(turn) == nil
    end

    test "returns nil when cursor is out of bounds" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")

      # Edge case: simulate invalid internal state for defensive programming test
      turn = %{turn | cursor: 5}
      assert Turn.get_active_player(turn) == nil
    end
  end

  describe "player advancement through phases" do
    test "advances to next player when transitioning from results to waiting" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        # Go through complete phase cycle to reach :results
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()

      # results -> waiting
      updated_turn = Turn.next_phase(turn)

      assert updated_turn.cursor == 1
      assert updated_turn.phase == :waiting
      assert updated_turn.queue == ["player-1", "player-2"]
    end

    test "advances from middle to next player through phase cycle" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        # Go through one complete cycle to advance to player-2
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting (advances to player-2)
        |> Turn.next_phase()
        # Now go through another cycle to get back to results
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()

      # results -> waiting (should advance to player-1)
      updated_turn = Turn.next_phase(turn)

      assert updated_turn.cursor == 0
      assert updated_turn.phase == :waiting
    end

    test "wraps around to the beginning when reaching the end" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        # Go through two complete cycles to reach player-1 again (wrap around)
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting (advances to player-2)
        |> Turn.next_phase()
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()

      # results -> waiting (wraps to player-1)
      updated_turn = Turn.next_phase(turn)

      assert updated_turn.cursor == 0
      assert updated_turn.phase == :waiting
    end

    test "stays at position 0 with single player" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        # Go through complete phase cycle
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()

      # results -> waiting
      updated_turn = Turn.next_phase(turn)

      assert updated_turn.cursor == 0
      assert updated_turn.phase == :waiting
    end

    test "handles two-player circular rotation" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        # Go through complete phase cycle
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()

      # First cycle: 0 -> 1
      # results -> waiting
      turn1 = Turn.next_phase(turn)
      assert turn1.cursor == 1
      assert turn1.phase == :waiting

      # Second cycle: 1 -> 0 (wrap around)
      turn2 =
        turn1
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting
        |> Turn.next_phase()

      assert turn2.cursor == 0
      assert turn2.phase == :waiting

      # Third cycle: 0 -> 1 (circular again)
      turn3 =
        turn2
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting
        |> Turn.next_phase()

      assert turn3.cursor == 1
      assert turn3.phase == :waiting
    end

    test "handles empty queue gracefully" do
      turn =
        Turn.new()
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()

      # results -> waiting
      result = Turn.next_phase(turn)

      assert result.queue == []
      assert result.cursor == 0
      assert result.phase == :waiting
    end

    test "clears turn data when transitioning from results to waiting" do
      track = Track.new(title: "Test", artist: "Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.set_track(track)
        # Go through complete phase cycle
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()

      # results -> waiting
      updated_turn = Turn.next_phase(turn)

      assert updated_turn.cursor == 1
      assert updated_turn.phase == :waiting
      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.track == nil
    end
  end

  describe "add_player_to_queue/2" do
    test "adds a player to the end of the queue" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")

      updated_turn = Turn.add_player_to_queue(turn, "player-2")

      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.cursor == 0
    end

    test "adds player to empty queue" do
      turn = Turn.new()
      updated_turn = Turn.add_player_to_queue(turn, "player-1")

      assert updated_turn.queue == ["player-1"]
      assert updated_turn.cursor == 0
    end

    test "adds multiple players sequentially" do
      turn = Turn.new()

      turn1 = Turn.add_player_to_queue(turn, "player-1")
      turn2 = Turn.add_player_to_queue(turn1, "player-2")
      turn3 = Turn.add_player_to_queue(turn2, "player-3")

      assert turn3.queue == ["player-1", "player-2", "player-3"]
      assert turn3.cursor == 0
    end

    test "preserves current player index when adding player" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        # Advance to player-2
        |> advance_to_player(1)

      updated_turn = Turn.add_player_to_queue(turn, "player-3")

      assert updated_turn.queue == ["player-1", "player-2", "player-3"]
      assert updated_turn.cursor == 1
    end

    test "preserves other fields when adding player" do
      track = Track.new(title: "Test", artist: "Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.set_track(track)

      updated_turn = Turn.add_player_to_queue(turn, "player-2")

      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.track == track
    end
  end

  describe "remove_player_from_queue/2" do
    # Helper function to advance to a specific player index using public API
    defp advance_to_player(turn, target_index) do
      current_index = turn.cursor

      cycles_needed =
        if target_index >= current_index,
          do: target_index - current_index,
          else: length(turn.queue) - current_index + target_index

      Enum.reduce(1..cycles_needed, turn, fn _, acc ->
        acc
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting (advances player)
        |> Turn.next_phase()
      end)
    end

    test "removes a player from the queue" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")
        # Set to player-2
        |> advance_to_player(1)

      updated_turn = Turn.remove_player_from_queue(turn, "player-2")

      assert updated_turn.queue == ["player-1", "player-3"]
      assert updated_turn.cursor == 1
    end

    test "adjusts current player index when removing a player before current player" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")
        # Set to player-3
        |> advance_to_player(2)

      updated_turn = Turn.remove_player_from_queue(turn, "player-1")

      assert updated_turn.queue == ["player-2", "player-3"]
      assert updated_turn.cursor == 1
    end

    test "keeps current player index when removing a player after current player" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")

      updated_turn = Turn.remove_player_from_queue(turn, "player-3")

      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.cursor == 0
    end

    test "handles removing current player" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")
        # Set to player-2
        |> advance_to_player(1)

      updated_turn = Turn.remove_player_from_queue(turn, "player-2")

      assert updated_turn.queue == ["player-1", "player-3"]
      # Index stays at 1, now pointing to "player-3"
      assert updated_turn.cursor == 1
    end

    test "handles removing current player when current is last" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")
        # Set to player-3
        |> advance_to_player(2)

      updated_turn = Turn.remove_player_from_queue(turn, "player-3")

      assert updated_turn.queue == ["player-1", "player-2"]
      # Index wraps around to 0
      assert updated_turn.cursor == 0
    end

    test "handles removing only player in queue" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")

      updated_turn = Turn.remove_player_from_queue(turn, "player-1")

      assert updated_turn.queue == []
      assert updated_turn.cursor == 0
    end

    test "handles removing non-existent player" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        # Set to player-2
        |> advance_to_player(1)

      updated_turn = Turn.remove_player_from_queue(turn, "non-existent")

      # Should remain unchanged
      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.cursor == 1
    end

    test "handles removing from empty queue" do
      turn = Turn.new()
      updated_turn = Turn.remove_player_from_queue(turn, "player-1")

      assert updated_turn.queue == []
      assert updated_turn.cursor == 0
    end

    test "handles complex removal scenarios" do
      # Test multiple removals with index adjustments
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("a")
        |> Turn.add_player_to_queue("b")
        |> Turn.add_player_to_queue("c")
        |> Turn.add_player_to_queue("d")
        |> Turn.add_player_to_queue("e")
        # Set to "d"
        |> advance_to_player(3)

      # Remove player before current (index should decrease)
      turn1 = Turn.remove_player_from_queue(turn, "b")
      assert turn1.queue == ["a", "c", "d", "e"]
      # 3 -> 2
      assert turn1.cursor == 2

      # Remove current player (index should stay, now pointing to next)
      turn2 = Turn.remove_player_from_queue(turn1, "d")
      assert turn2.queue == ["a", "c", "e"]
      # Now pointing to "e"
      assert turn2.cursor == 2

      # Remove last player when current is last (should wrap)
      turn3 = Turn.remove_player_from_queue(turn2, "e")
      assert turn3.queue == ["a", "c"]
      # Wrapped to beginning
      assert turn3.cursor == 0
    end

    test "preserves other fields when removing player" do
      track = Track.new(title: "Test", artist: "Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.set_track(track)

      updated_turn = Turn.remove_player_from_queue(turn, "player-2")

      assert updated_turn.queue == ["player-1"]
      assert updated_turn.cursor == 0
      assert updated_turn.track == track
    end
  end

  describe "set_track/2" do
    test "sets the track for the turn" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")

      track = Track.new(title: "Song", artist: "Artist", year: 2020)
      updated_turn = Turn.set_track(turn, track)

      assert updated_turn.track == track
      # Other fields unchanged
      assert updated_turn.queue == ["player-1"]
    end

    test "replaces existing track" do
      old_track = Track.new(title: "Old Song", artist: "Old Artist", year: 2019)
      new_track = Track.new(title: "New Song", artist: "New Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.set_track(old_track)

      updated_turn = Turn.set_track(turn, new_track)

      assert updated_turn.track == new_track
      assert updated_turn.track.title == "New Song"
    end

    test "preserves other fields when setting track" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        # Set to player-2
        |> advance_to_player(1)

      track = Track.new(title: "Test", artist: "Artist", year: 2020)
      updated_turn = Turn.set_track(turn, track)

      assert updated_turn.track == track
      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.cursor == 1
    end
  end

  describe "edge cases and integration" do
    test "handles complete turn lifecycle" do
      # Start with turn that has queue
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("alice")
        |> Turn.add_player_to_queue("bob")
        |> Turn.add_player_to_queue("charlie")

      assert length(turn.queue) == 3
      assert turn.cursor == 0

      # Set track
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2020)
      turn = Turn.set_track(turn, track)
      assert turn.track == track

      # Move through players
      current_player = Turn.get_active_player(turn)
      assert current_player in ["alice", "bob", "charlie"]

      # Verify track is maintained before transition
      assert turn.track == track

      # After phase transition, track is cleared
      turn =
        turn
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting (clears data, advances player)
        |> Turn.next_phase()

      assert turn.track == nil
    end

    test "handles single player scenarios" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("only-player")

      # Current player operations
      assert Turn.get_active_player(turn) == "only-player"

      # Next player should stay the same after complete cycle
      next_turn =
        turn
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # results -> waiting
        |> Turn.next_phase()

      assert next_turn.cursor == 0
      assert Turn.get_active_player(next_turn) == "only-player"

      # Remove the only player
      empty_turn = Turn.remove_player_from_queue(turn, "only-player")
      assert empty_turn.queue == []
      assert Turn.get_active_player(empty_turn) == nil
    end

    test "validates queue consistency after operations" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("a")
        |> Turn.add_player_to_queue("b")
        |> Turn.add_player_to_queue("c")
        |> Turn.add_player_to_queue("d")

      # Perform multiple operations
      # Move to index 1 using natural progression
      turn = advance_to_player(turn, 1)
      # Remove first, index should adjust to 0
      turn = Turn.remove_player_from_queue(turn, "a")
      # Add new player
      turn = Turn.add_player_to_queue(turn, "e")
      # Move to next using natural progression
      turn = advance_to_player(turn, 1)

      # Verify consistency
      assert length(turn.queue) == 4
      assert "a" not in turn.queue
      assert "e" in turn.queue
      assert turn.cursor < length(turn.queue)

      current_player = Turn.get_active_player(turn)
      assert current_player != nil
      assert current_player in turn.queue
    end
  end

  describe "next_phase/1" do
    test "transitions from waiting to ready" do
      turn = Turn.new()
      updated_turn = Turn.next_phase(turn)
      assert updated_turn.phase == :ready
    end

    test "transitions from ready to steady" do
      turn = Turn.new() |> Turn.next_phase()
      updated_turn = Turn.next_phase(turn)
      assert updated_turn.phase == :steady
    end

    test "transitions from steady to challenging" do
      turn = Turn.new() |> Turn.next_phase() |> Turn.next_phase()
      updated_turn = Turn.next_phase(turn)
      assert updated_turn.phase == :challenging
    end

    test "transitions from challenging to results" do
      turn = Turn.new() |> Turn.next_phase() |> Turn.next_phase() |> Turn.next_phase()
      updated_turn = Turn.next_phase(turn)
      assert updated_turn.phase == :results
    end

    test "transitions from results to waiting with cleared data and next player" do
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.set_track(track)
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting
        |> Turn.next_phase()

      assert turn.phase == :waiting
      assert turn.track == nil
      assert turn.cursor == 1
      assert Turn.get_active_player(turn) == "player-2"
      assert turn.queue == ["player-1", "player-2"]
    end

    test "handles single player wrap around in results transition" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("only-player")
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting
        |> Turn.next_phase()

      assert turn.phase == :waiting
      assert turn.cursor == 0
      assert Turn.get_active_player(turn) == "only-player"
    end

    test "preserves queue and player index for non-results transitions" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.next_phase()

      assert turn.phase == :ready
      assert turn.cursor == 0
      assert Turn.get_active_player(turn) == "player-1"
    end
  end

  describe "phase workflow integration" do
    test "complete phase cycle" do
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("alice")
        |> Turn.add_player_to_queue("bob")

      assert turn.phase == :waiting
      assert Turn.get_active_player(turn) == "alice"

      # Move through all phases
      turn = Turn.next_phase(turn)
      assert turn.phase == :ready

      turn = Turn.set_track(turn, track)
      turn = Turn.next_phase(turn)
      assert turn.phase == :steady

      turn = Turn.next_phase(turn)
      assert turn.phase == :challenging

      turn = Turn.next_phase(turn)
      assert turn.phase == :results

      # Transition to next turn using new workflow: clear data first, then change phase
      # results -> waiting (clears data and advances player)
      turn = turn |> Turn.next_phase()

      assert turn.phase == :waiting
      assert turn.track == nil
      assert Turn.get_active_player(turn) == "bob"
    end

    test "phase transitions preserve essential turn state" do
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")

      original_queue = turn.queue

      # Go through a complete cycle using new workflow
      turn =
        turn
        # waiting -> ready
        |> Turn.next_phase()
        # Set track and ready -> steady
        |> Turn.set_track(track)
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting (clear data and advance player)
        |> Turn.next_phase()

      # Queue should remain the same, but current player should advance
      assert turn.queue == original_queue
      assert turn.cursor == 1
      assert Turn.get_active_player(turn) == "player-2"
      assert turn.phase == :waiting
    end
  end

  describe "add_assumption/3" do
    test "adds assumption for player" do
      turn = Turn.new()
      updated_turn = Turn.add_assumption(turn, 2, "player-1")

      assert updated_turn.assumptions == [%{position: 2, user_id: "player-1"}]
    end

    test "preserves previous assumptions from same player (FIFO behavior)" do
      turn =
        Turn.new()
        |> Turn.add_assumption(1, "player-1")
        |> Turn.add_assumption(3, "player-1")

      assert turn.assumptions == [%{position: 1, user_id: "player-1"}, %{position: 3, user_id: "player-1"}]
    end

    test "keeps assumptions from different players in chronological order" do
      turn =
        Turn.new()
        |> Turn.add_assumption(1, "player-1")
        |> Turn.add_assumption(2, "player-2")
        |> Turn.add_assumption(3, "player-1")

      assert turn.assumptions == [
               %{position: 1, user_id: "player-1"},
               %{position: 2, user_id: "player-2"},
               %{position: 3, user_id: "player-1"}
             ]
    end

    test "handles zero position" do
      turn = Turn.new() |> Turn.add_assumption(0, "player-1")

      assert turn.assumptions == [%{position: 0, user_id: "player-1"}]
    end

    test "maintains chronological order for multiple players" do
      turn =
        Turn.new()
        |> Turn.add_assumption(1, "player-1")
        |> Turn.add_assumption(2, "player-2")
        |> Turn.add_assumption(3, "player-3")
        |> Turn.add_assumption(4, "player-1")
        |> Turn.add_assumption(5, "player-2")

      expected = [
        %{position: 1, user_id: "player-1"},
        %{position: 2, user_id: "player-2"},
        %{position: 3, user_id: "player-3"},
        %{position: 4, user_id: "player-1"},
        %{position: 5, user_id: "player-2"}
      ]

      assert turn.assumptions == expected
    end
  end

  describe "set_timeline_snapshot/2" do
    test "sets timeline snapshot" do
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      timeline = [track1, track2]

      turn = Turn.new() |> Turn.set_timeline_snapshot(timeline)

      assert turn.timeline == timeline
    end

    test "replaces existing timeline" do
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      turn =
        Turn.new()
        |> Turn.set_timeline_snapshot([track1])
        |> Turn.set_timeline_snapshot([track2, track3])

      assert turn.timeline == [track2, track3]
    end

    test "handles empty timeline" do
      turn = Turn.new() |> Turn.set_timeline_snapshot([])

      assert turn.timeline == []
    end
  end

  describe "clear_challenging_data/1 (via phase transitions)" do
    test "clears timeline and assumptions when transitioning from results to waiting" do
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.set_timeline_snapshot([track1, track2])
        |> Turn.add_assumption(1, "player-1")
        |> Turn.add_assumption(2, "player-2")
        # Move to results phase
        # waiting -> ready
        |> Turn.next_phase()
        # ready -> steady
        |> Turn.next_phase()
        # steady -> challenging
        |> Turn.next_phase()
        # challenging -> results
        |> Turn.next_phase()
        # results -> waiting (clears data)
        |> Turn.next_phase()

      assert turn.timeline == []
      assert turn.assumptions == []
      assert turn.phase == :waiting
    end

    test "preserves challenging data during other phase transitions" do
      track = Track.new(title: "Song", artist: "Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.set_timeline_snapshot([track])
        |> Turn.add_assumption(1, "player-1")
        # waiting -> ready
        |> Turn.next_phase()

      assert turn.timeline == [track]
      assert turn.assumptions == [%{position: 1, user_id: "player-1"}]
      assert turn.phase == :ready
    end
  end

  describe "new/0 with challenging fields" do
    test "creates turn with empty timeline and assumptions" do
      turn = Turn.new()

      assert turn.timeline == []
      assert turn.assumptions == []
    end
  end

  describe "update_timeline/3" do
    test "adds track to turn timeline at head by default" do
      turn = Turn.new()
      track = Track.new(title: "Song", artist: "Artist", year: 2023)

      updated_turn = Turn.update_timeline(turn, track)

      assert updated_turn.timeline == [track]
    end

    test "adds multiple tracks to timeline" do
      turn = Turn.new()
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)

      turn_with_first = Turn.update_timeline(turn, track1)
      turn_with_both = Turn.update_timeline(turn_with_first, track2)

      assert turn_with_both.timeline == [track2, track1]
    end

    test "adds track to head with position: 0" do
      turn = Turn.new()
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)

      turn_with_first = Turn.update_timeline(turn, track1)
      turn_with_both = Turn.update_timeline(turn_with_first, track2, 0)

      assert turn_with_both.timeline == [track2, track1]
    end

    test "adds track to specific position in timeline" do
      turn = Turn.new()
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      turn_with_timeline =
        turn
        |> Turn.update_timeline(track1)
        |> Turn.update_timeline(track2)

      updated_turn = Turn.update_timeline(turn_with_timeline, track3, 1)

      assert updated_turn.timeline == [track2, track3, track1]
    end

    test "adds track at end when position equals list length" do
      turn = Turn.new()
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      turn_with_timeline =
        turn
        |> Turn.update_timeline(track1)
        |> Turn.update_timeline(track2)

      updated_turn = Turn.update_timeline(turn_with_timeline, track3, 2)

      assert updated_turn.timeline == [track2, track1, track3]
    end

    test "adds track at end when position is greater than list length" do
      turn = Turn.new()
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)

      turn_with_first = Turn.update_timeline(turn, track1)

      updated_turn = Turn.update_timeline(turn_with_first, track2, 999)

      assert updated_turn.timeline == [track1, track2]
    end

    test "validates position argument types" do
      turn = Turn.new()
      track = Track.new(title: "Song", artist: "Artist", year: 2023)

      assert_raise FunctionClauseError, fn ->
        Turn.update_timeline(turn, track, "invalid")
      end

      assert_raise FunctionClauseError, fn ->
        Turn.update_timeline(turn, track, -1)
      end
    end

    test "supports multiple position options scenarios" do
      turn = Turn.new()

      tracks =
        for i <- 1..5 do
          Track.new(title: "Song #{i}", artist: "Artist #{i}", year: 2020 + i)
        end

      [track1, track2, track3, track4, track5] = tracks

      # Build timeline: [track1]
      turn = Turn.update_timeline(turn, track1)

      # Insert at position 0: [track2, track1]
      turn = Turn.update_timeline(turn, track2, 0)

      # Insert at position 2 (end): [track2, track1, track3]
      turn = Turn.update_timeline(turn, track3, 2)

      # Insert at position 1: [track2, track4, track1, track3]
      turn = Turn.update_timeline(turn, track4, 1)

      # Insert at position 999 (end): [track2, track4, track1, track3, track5]
      turn = Turn.update_timeline(turn, track5, 999)

      expected = [track2, track4, track1, track3, track5]
      assert turn.timeline == expected
    end

    test "adds duplicate tracks at different positions" do
      turn = Turn.new()
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)

      # Add two tracks: [track2, track1]
      turn_with_timeline =
        turn
        |> Turn.update_timeline(track1)
        |> Turn.update_timeline(track2)

      # Add track1 again at position 0: [track1, track2, track1]
      updated_turn = Turn.update_timeline(turn_with_timeline, track1, 0)

      assert length(updated_turn.timeline) == 3
      assert Enum.at(updated_turn.timeline, 0).id == track1.id
      assert Enum.at(updated_turn.timeline, 1).id == track2.id  
      assert Enum.at(updated_turn.timeline, 2).id == track1.id
    end
  end

  describe "reorder_timeline/3" do
    setup do
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      turn =
        Turn.new()
        |> Turn.update_timeline(track1)
        |> Turn.update_timeline(track2)
        |> Turn.update_timeline(track3)

      %{turn: turn, track1: track1, track2: track2, track3: track3}
    end

    test "moves track to beginning of timeline", %{
      turn: turn,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      # Move track1 to position 0: [track1, track3, track2]
      {:ok, updated_turn} = Turn.reorder_timeline(turn, track1.id, 0)

      assert updated_turn.timeline == [track1, track3, track2]
    end

    test "moves track to middle of timeline", %{
      turn: turn,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      # Move track1 to position 1: [track3, track1, track2]
      {:ok, updated_turn} = Turn.reorder_timeline(turn, track1.id, 1)

      assert updated_turn.timeline == [track3, track1, track2]
    end

    test "moves track to end of timeline", %{
      turn: turn,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      # Move track3 to position 2: [track2, track1, track3]
      {:ok, updated_turn} = Turn.reorder_timeline(turn, track3.id, 2)

      assert updated_turn.timeline == [track2, track1, track3]
    end

    test "handles position beyond timeline length", %{
      turn: turn,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      {:ok, updated_turn} = Turn.reorder_timeline(turn, track1.id, 10)

      assert updated_turn.timeline == [track3, track2, track1]
    end

    test "returns error for non-existent track", %{turn: turn} do
      non_existent_id = "non_existent_track_id"

      result = Turn.reorder_timeline(turn, non_existent_id, 0)

      assert result == {:error, :track_not_found}
    end

    test "moving track to same position leaves timeline unchanged", %{
      turn: turn,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      # Move track2 to its current position (index 1)
      {:ok, updated_turn} = Turn.reorder_timeline(turn, track2.id, 1)

      assert updated_turn.timeline == [track3, track2, track1]
    end

    test "works with empty timeline" do
      turn = Turn.new()

      result = Turn.reorder_timeline(turn, "any_id", 0)

      assert result == {:error, :track_not_found}
    end

    test "works with single track timeline" do
      track = Track.new(title: "Song", artist: "Artist", year: 2020)
      turn = Turn.update_timeline(Turn.new(), track)

      {:ok, updated_turn} = Turn.reorder_timeline(turn, track.id, 0)

      assert updated_turn.timeline == [track]
    end

    test "synchronizes assumptions when track moves left", %{
      turn: turn,
      track1: track1,
      track2: _track2,
      track3: _track3
    } do
      # Setup assumptions: player1 on track1(pos 2), player2 on track2(pos 1), player3 on track3(pos 0)
      turn =
        turn
        # track1 at position 2
        |> Turn.add_assumption(2, "player1")
        # track2 at position 1
        |> Turn.add_assumption(1, "player2")
        # track3 at position 0
        |> Turn.add_assumption(0, "player3")

      # Move track1 from position 2 to position 0 (left): [track1, track3, track2]
      {:ok, updated_turn} = Turn.reorder_timeline(turn, track1.id, 0)

      # Expected: track1(pos 2->0), track3(pos 0->1), track2(pos 1->2)
      # Assumptions update independently in original chronological order:
      # - player1 (was on pos 2): follows track1 to new position 0
      # - player2 (was on pos 1): track2 shifts from pos 1 to pos 2
      # - player3 (was on pos 0): track3 shifts from pos 0 to pos 1
      expected_assumptions = [
        # player1: track1 moved from pos 2 to pos 0
        %{position: 0, user_id: "player1"},
        # player2: track2 moved from pos 1 to pos 2
        %{position: 2, user_id: "player2"},
        # player3: track3 moved from pos 0 to pos 1
        %{position: 1, user_id: "player3"}
      ]

      assert updated_turn.assumptions == expected_assumptions
    end

    test "synchronizes assumptions when track moves right", %{
      turn: turn,
      track1: _track1,
      track2: _track2,
      track3: track3
    } do
      # Setup assumptions
      turn =
        turn
        # track1 at position 2
        |> Turn.add_assumption(2, "player1")
        # track2 at position 1
        |> Turn.add_assumption(1, "player2")
        # track3 at position 0
        |> Turn.add_assumption(0, "player3")

      # Move track3 from position 0 to position 2 (right): [track2, track1, track3]
      {:ok, updated_turn} = Turn.reorder_timeline(turn, track3.id, 2)

      # Expected: track3(pos 0->2), track2(pos 1->0), track1(pos 2->1)
      # Assumptions should be: player1(2->1), player2(1->0), player3(0->2, moved to end)
      expected_assumptions = [
        # track1 moved from pos 2 to pos 1
        %{position: 1, user_id: "player1"},
        # track2 moved from pos 1 to pos 0
        %{position: 0, user_id: "player2"},
        # track3 moved from pos 0 to pos 2 (at end of array)
        %{position: 2, user_id: "player3"}
      ]

      assert updated_turn.assumptions == expected_assumptions
    end

    test "handles empty assumptions during reorder", %{
      turn: turn,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      # No assumptions, just reorder
      {:ok, updated_turn} = Turn.reorder_timeline(turn, track1.id, 0)

      assert updated_turn.assumptions == []
      assert updated_turn.timeline == [track1, track3, track2]
    end
  end
end
