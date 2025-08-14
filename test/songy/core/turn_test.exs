defmodule Songy.Core.TurnTest do
  use ExUnit.Case, async: true

  alias Songy.Core.{Turn, Track}

  describe "new/0" do
    test "creates turn with default values" do
      turn = Turn.new()

      assert %Turn{} = turn
      assert turn.queue == []
      assert turn.current_player_index == 0
      assert turn.challengers == []
      assert turn.track == nil
      assert turn.phase == :turn_waiting
    end
  end

  describe "get_current_player/1" do
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

      assert Turn.get_current_player(turn) == "player-2"
    end

    test "returns first player when current_player_index is 0" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")

      assert Turn.get_current_player(turn) == "player-1"
    end

    test "returns last player when current_player_index points to last element" do
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

      assert Turn.get_current_player(turn) == "player-3"
    end

    test "returns nil when queue is empty" do
      turn = Turn.new()
      assert Turn.get_current_player(turn) == nil
    end

    test "returns nil when current_player_index is out of bounds" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")

      # Edge case: simulate invalid internal state for defensive programming test
      turn = %{turn | current_player_index: 5}
      assert Turn.get_current_player(turn) == nil
    end
  end

  describe "player advancement through phases" do
    test "advances to next player when transitioning from results to waiting" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        # Go through complete phase cycle to reach :turn_results
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

      assert updated_turn.current_player_index == 1
      assert updated_turn.phase == :turn_waiting
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

      assert updated_turn.current_player_index == 0
      assert updated_turn.phase == :turn_waiting
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

      assert updated_turn.current_player_index == 0
      assert updated_turn.phase == :turn_waiting
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

      assert updated_turn.current_player_index == 0
      assert updated_turn.phase == :turn_waiting
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
      assert turn1.current_player_index == 1
      assert turn1.phase == :turn_waiting

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

      assert turn2.current_player_index == 0
      assert turn2.phase == :turn_waiting

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

      assert turn3.current_player_index == 1
      assert turn3.phase == :turn_waiting
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
      assert result.current_player_index == 0
      assert result.phase == :turn_waiting
    end

    test "clears turn data when transitioning from results to waiting" do
      track = Track.new(title: "Test", artist: "Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_challenger("challenger-1")
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

      assert updated_turn.current_player_index == 1
      assert updated_turn.phase == :turn_waiting
      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.challengers == []
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
      assert updated_turn.current_player_index == 0
    end

    test "adds player to empty queue" do
      turn = Turn.new()
      updated_turn = Turn.add_player_to_queue(turn, "player-1")

      assert updated_turn.queue == ["player-1"]
      assert updated_turn.current_player_index == 0
    end

    test "adds multiple players sequentially" do
      turn = Turn.new()

      turn1 = Turn.add_player_to_queue(turn, "player-1")
      turn2 = Turn.add_player_to_queue(turn1, "player-2")
      turn3 = Turn.add_player_to_queue(turn2, "player-3")

      assert turn3.queue == ["player-1", "player-2", "player-3"]
      assert turn3.current_player_index == 0
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
      assert updated_turn.current_player_index == 1
    end

    test "preserves other fields when adding player" do
      challengers = ["challenger-1"]
      track = Track.new(title: "Test", artist: "Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_challenger("challenger-1")
        |> Turn.set_track(track)

      updated_turn = Turn.add_player_to_queue(turn, "player-2")

      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.challengers == challengers
      assert updated_turn.track == track
    end
  end

  describe "remove_player_from_queue/2" do
    # Helper function to advance to a specific player index using public API
    defp advance_to_player(turn, target_index) do
      current_index = turn.current_player_index

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
      assert updated_turn.current_player_index == 1
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
      assert updated_turn.current_player_index == 1
    end

    test "keeps current player index when removing a player after current player" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")

      updated_turn = Turn.remove_player_from_queue(turn, "player-3")

      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.current_player_index == 0
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
      assert updated_turn.current_player_index == 1
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
      assert updated_turn.current_player_index == 0
    end

    test "handles removing only player in queue" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")

      updated_turn = Turn.remove_player_from_queue(turn, "player-1")

      assert updated_turn.queue == []
      assert updated_turn.current_player_index == 0
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
      assert updated_turn.current_player_index == 1
    end

    test "handles removing from empty queue" do
      turn = Turn.new()
      updated_turn = Turn.remove_player_from_queue(turn, "player-1")

      assert updated_turn.queue == []
      assert updated_turn.current_player_index == 0
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
      assert turn1.current_player_index == 2

      # Remove current player (index should stay, now pointing to next)
      turn2 = Turn.remove_player_from_queue(turn1, "d")
      assert turn2.queue == ["a", "c", "e"]
      # Now pointing to "e"
      assert turn2.current_player_index == 2

      # Remove last player when current is last (should wrap)
      turn3 = Turn.remove_player_from_queue(turn2, "e")
      assert turn3.queue == ["a", "c"]
      # Wrapped to beginning
      assert turn3.current_player_index == 0
    end

    test "preserves other fields when removing player" do
      challengers = ["challenger-1"]
      track = Track.new(title: "Test", artist: "Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_challenger("challenger-1")
        |> Turn.set_track(track)

      updated_turn = Turn.remove_player_from_queue(turn, "player-2")

      assert updated_turn.queue == ["player-1"]
      assert updated_turn.current_player_index == 0
      assert updated_turn.challengers == challengers
      assert updated_turn.track == track
    end
  end

  describe "add_challenger/2" do
    test "adds a challenger to empty challengers list" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")

      updated_turn = Turn.add_challenger(turn, "challenger-1")

      assert updated_turn.challengers == ["challenger-1"]
      # Queue unchanged
      assert updated_turn.queue == ["player-1"]
    end

    test "adds multiple challengers to the turn" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_challenger("first-challenger")

      updated_turn = Turn.add_challenger(turn, "second-challenger")

      assert updated_turn.challengers == ["first-challenger", "second-challenger"]
    end

    test "adds challenger sequentially" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")

      turn1 = Turn.add_challenger(turn, "challenger-1")
      turn2 = Turn.add_challenger(turn1, "challenger-2")
      turn3 = Turn.add_challenger(turn2, "challenger-3")

      assert turn3.challengers == ["challenger-1", "challenger-2", "challenger-3"]
    end

    test "preserves other fields when adding challenger" do
      track = Track.new(title: "Test", artist: "Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        # Set to player-2
        |> advance_to_player(1)
        |> Turn.set_track(track)

      updated_turn = Turn.add_challenger(turn, "challenger-1")

      assert updated_turn.challengers == ["challenger-1"]
      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.current_player_index == 1
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
      challengers = ["challenger-1", "challenger-2"]

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        # Set to player-2
        |> advance_to_player(1)
        |> Turn.add_challenger("challenger-1")
        |> Turn.add_challenger("challenger-2")

      track = Track.new(title: "Test", artist: "Artist", year: 2020)
      updated_turn = Turn.set_track(turn, track)

      assert updated_turn.track == track
      assert updated_turn.queue == ["player-1", "player-2"]
      assert updated_turn.current_player_index == 1
      assert updated_turn.challengers == challengers
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
      assert turn.current_player_index == 0

      # Add challengers
      turn = Turn.add_challenger(turn, "challenger-1")
      turn = Turn.add_challenger(turn, "challenger-2")
      assert length(turn.challengers) == 2

      # Set track
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2020)
      turn = Turn.set_track(turn, track)
      assert turn.track == track

      # Move through players
      current_player = Turn.get_current_player(turn)
      assert current_player in ["alice", "bob", "charlie"]

      # Verify all fields are maintained before transition
      assert length(turn.challengers) == 2
      assert turn.track == track

      # After phase transition, challengers and track are cleared
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

      assert length(turn.challengers) == 0
      assert turn.track == nil
    end

    test "handles single player scenarios" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("only-player")

      # Current player operations
      assert Turn.get_current_player(turn) == "only-player"

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

      assert next_turn.current_player_index == 0
      assert Turn.get_current_player(next_turn) == "only-player"

      # Remove the only player
      empty_turn = Turn.remove_player_from_queue(turn, "only-player")
      assert empty_turn.queue == []
      assert Turn.get_current_player(empty_turn) == nil
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
      assert turn.current_player_index < length(turn.queue)

      current_player = Turn.get_current_player(turn)
      assert current_player != nil
      assert current_player in turn.queue
    end
  end

  describe "get_phase/1" do
    test "returns the current phase" do
      turn = Turn.new()
      assert Turn.get_phase(turn) == :turn_waiting
    end

    test "returns phase after setting it" do
      turn = Turn.new() |> Turn.next_phase()
      assert Turn.get_phase(turn) == :turn_ready
    end
  end

  describe "next_phase/1" do
    test "transitions from waiting to ready" do
      turn = Turn.new()
      updated_turn = Turn.next_phase(turn)
      assert updated_turn.phase == :turn_ready
    end

    test "transitions from ready to steady" do
      turn = Turn.new() |> Turn.next_phase()
      updated_turn = Turn.next_phase(turn)
      assert updated_turn.phase == :turn_steady
    end

    test "transitions from steady to challenging" do
      turn = Turn.new() |> Turn.next_phase() |> Turn.next_phase()
      updated_turn = Turn.next_phase(turn)
      assert updated_turn.phase == :turn_challenging
    end

    test "transitions from challenging to results" do
      turn = Turn.new() |> Turn.next_phase() |> Turn.next_phase() |> Turn.next_phase()
      updated_turn = Turn.next_phase(turn)
      assert updated_turn.phase == :turn_results
    end

    test "transitions from results to waiting with cleared data and next player" do
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_challenger("challenger-1")
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

      assert turn.phase == :turn_waiting
      assert turn.challengers == []
      assert turn.track == nil
      assert turn.current_player_index == 1
      assert Turn.get_current_player(turn) == "player-2"
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

      assert turn.phase == :turn_waiting
      assert turn.current_player_index == 0
      assert Turn.get_current_player(turn) == "only-player"
    end

    test "preserves queue and player index for non-results transitions" do
      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.next_phase()

      assert turn.phase == :turn_ready
      assert turn.current_player_index == 0
      assert Turn.get_current_player(turn) == "player-1"
    end
  end

  describe "phase workflow integration" do
    test "complete phase cycle" do
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2020)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("alice")
        |> Turn.add_player_to_queue("bob")

      assert turn.phase == :turn_waiting
      assert Turn.get_current_player(turn) == "alice"

      # Move through all phases
      turn = Turn.next_phase(turn)
      assert turn.phase == :turn_ready

      turn = Turn.set_track(turn, track)
      turn = Turn.next_phase(turn)
      assert turn.phase == :turn_steady

      turn = Turn.next_phase(turn)
      assert turn.phase == :turn_challenging

      turn = Turn.add_challenger(turn, "challenger-1")
      turn = Turn.next_phase(turn)
      assert turn.phase == :turn_results

      # Transition to next turn using new workflow: clear data first, then change phase
      # results -> waiting (clears data and advances player)
      turn = turn |> Turn.next_phase()

      assert turn.phase == :turn_waiting
      assert turn.challengers == []
      assert turn.track == nil
      assert Turn.get_current_player(turn) == "bob"
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
        # Add challenger and challenging -> results
        |> Turn.add_challenger("challenger-1")
        |> Turn.next_phase()
        # results -> waiting (clear data and advance player)
        |> Turn.next_phase()

      # Queue should remain the same, but current player should advance
      assert turn.queue == original_queue
      assert turn.current_player_index == 1
      assert Turn.get_current_player(turn) == "player-2"
      assert turn.phase == :turn_waiting
    end
  end
end
