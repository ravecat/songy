defmodule Songy.Core.TurnTest do
  use ExUnit.Case, async: true

  alias Songy.Core.{Turn, Track}

  describe "new/1" do
    test "creates turn with required player_id" do
      player_id = "player-uuid-123"
      turn = Turn.new(player_id: player_id)

      assert %Turn{} = turn
      assert turn.player_id == player_id
      assert turn.challengers == []
      assert turn.track == nil
    end

    test "creates turn with player_id and challengers" do
      player_id = "player-uuid-123"
      challengers = ["player-uuid-456", "player-uuid-789"]
      turn = Turn.new(player_id: player_id, challengers: challengers)

      assert %Turn{} = turn
      assert turn.player_id == player_id
      assert turn.challengers == challengers
      assert turn.track == nil
    end

    test "creates turn with all fields" do
      player_id = "player-uuid-123"
      challengers = ["player-uuid-456"]
      track = Track.new(
        title: "Bohemian Rhapsody",
        artist: "Queen",
        year: 1975
      )

      turn = Turn.new(player_id: player_id, challengers: challengers, track: track)

      assert %Turn{} = turn
      assert turn.player_id == player_id
      assert turn.challengers == challengers
      assert turn.track == track
    end

    test "creates turn with empty challengers list when not provided" do
      player_id = "player-uuid-123"
      turn = Turn.new(player_id: player_id)

      assert turn.challengers == []
    end
  end

  describe "JSON encoding" do
    test "encodes turn to JSON correctly" do
      player_id = "player-uuid-123"
      challengers = ["player-uuid-456", "player-uuid-789"]
      turn = Turn.new(player_id: player_id, challengers: challengers)

      encoded = Jason.encode!(turn)

      assert encoded == ~s({"player_id":"player-uuid-123","challengers":["player-uuid-456","player-uuid-789"],"track":null})
    end

    test "encodes turn with track to JSON correctly" do
      player_id = "player-uuid-123"
      track = Track.new(
        title: "Test Song",
        artist: "Test Artist",
        year: 2023
      )
      turn = Turn.new(player_id: player_id, track: track)

      encoded = Jason.encode!(turn)

      assert String.contains?(encoded, ~s("player_id":"player-uuid-123"))
      assert String.contains?(encoded, ~s("track":))
      assert String.contains?(encoded, ~s("title":"Test Song"))
    end

    test "encodes default turn to JSON correctly" do
      turn = Turn.new(player_id: "test-player")

      encoded = Jason.encode!(turn)

      assert encoded == ~s({"player_id":"test-player","challengers":[],"track":null})
    end
  end

  describe "add_challenger/2" do
    test "adds challenger to empty challengers list" do
      turn = Turn.new(player_id: "player-1")
      updated_turn = Turn.add_challenger(turn, "challenger-1")

      assert updated_turn.challengers == ["challenger-1"]
      assert updated_turn.player_id == "player-1"
      assert updated_turn.track == nil
    end

    test "adds challenger to existing challengers list" do
      turn = Turn.new(player_id: "player-1", challengers: ["first-challenger"])
      updated_turn = Turn.add_challenger(turn, "second-challenger")

      assert updated_turn.challengers == ["first-challenger", "second-challenger"]
      assert updated_turn.player_id == "player-1"
    end

    test "preserves other turn fields when adding challenger" do
      track = Track.new(
        title: "Test Song",
        artist: "Test Artist",
        year: 2023
      )
      turn = Turn.new(player_id: "player-1", track: track, challengers: ["first"])
      updated_turn = Turn.add_challenger(turn, "second")

      assert updated_turn.challengers == ["first", "second"]
      assert updated_turn.player_id == "player-1"
      assert updated_turn.track == track
    end

    test "maintains FIFO order when adding multiple challengers" do
      turn = Turn.new(player_id: "active-player")

      # First user raises hand
      turn = Turn.add_challenger(turn, "user-1")
      assert turn.challengers == ["user-1"]
      assert hd(turn.challengers) == "user-1"  # First in queue

      # Second user raises hand
      turn = Turn.add_challenger(turn, "user-2")
      assert turn.challengers == ["user-1", "user-2"]
      assert hd(turn.challengers) == "user-1"  # First remains first

      # Third user raises hand
      turn = Turn.add_challenger(turn, "user-3")
      assert turn.challengers == ["user-1", "user-2", "user-3"]
      assert hd(turn.challengers) == "user-1"  # First still first

      # Fourth user raises hand
      turn = Turn.add_challenger(turn, "user-4")
      assert turn.challengers == ["user-1", "user-2", "user-3", "user-4"]
      assert hd(turn.challengers) == "user-1"  # Order preserved

      # Verify complete FIFO order
      assert Enum.at(turn.challengers, 0) == "user-1"  # First to raise hand
      assert Enum.at(turn.challengers, 1) == "user-2"  # Second to raise hand
      assert Enum.at(turn.challengers, 2) == "user-3"  # Third to raise hand
      assert Enum.at(turn.challengers, 3) == "user-4"  # Fourth to raise hand
    end
  end

  describe "set_track/2" do
    test "sets track on turn without existing track" do
      turn = Turn.new(player_id: "player-1")
      track = Track.new(
        title: "Test Song",
        artist: "Test Artist",
        year: 2023
      )
      updated_turn = Turn.set_track(turn, track)

      assert updated_turn.track == track
      assert updated_turn.player_id == "player-1"
      assert updated_turn.challengers == []
    end

    test "replaces existing track with new track" do
      old_track = Track.new(
        title: "Old Song",
        artist: "Old Artist",
        year: 2020
      )
      new_track = Track.new(
        title: "New Song",
        artist: "New Artist",
        year: 2023
      )
      turn = Turn.new(player_id: "player-1", track: old_track)
      updated_turn = Turn.set_track(turn, new_track)

      assert updated_turn.track == new_track
      assert updated_turn.player_id == "player-1"
    end

    test "preserves other turn fields when setting track" do
      track = Track.new(
        title: "Test Song",
        artist: "Test Artist",
        year: 2023
      )
      turn = Turn.new(player_id: "player-1", challengers: ["challenger-1", "challenger-2"])
      updated_turn = Turn.set_track(turn, track)

      assert updated_turn.track == track
      assert updated_turn.player_id == "player-1"
      assert updated_turn.challengers == ["challenger-1", "challenger-2"]
    end
  end
end
