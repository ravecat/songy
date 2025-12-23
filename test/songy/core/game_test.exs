defmodule Songy.Core.GameTest do
  use ExUnit.Case, async: true

  alias Songy.Core.{Game, Player, User, Track}

  describe "struct" do
    test "creates game with all fields" do
      now = DateTime.utc_now()
      user = %User{uuid: "user-1", name: "Player1"}

      game = %Game{
        id: "game-123",
        owner_id: "owner-456",
        max_participants: 10,
        max_score: 10,
        status: :waiting,
        participants: [user],
        scores: %{"user-1" => 5},
        player: Player.new(),
        timelines: %{},
        created_at: now,
        queue: ["user-1"],
        cursor: 0,
        track: nil
      }

      assert game.id == "game-123"
      assert game.owner_id == "owner-456"
      assert game.status == :waiting
      assert game.queue == ["user-1"]
      assert game.cursor == 0
      assert is_nil(game.track)
    end
  end

  describe "queue and cursor fields" do
    test "initializes with empty queue and zero cursor" do
      game = %Game{
        id: "game-123",
        owner_id: "owner-456",
        max_participants: 10,
        max_score: 10,
        status: :waiting,
        participants: [],
        scores: %{},
        player: Player.new(),
        timelines: %{},
        created_at: DateTime.utc_now(),
        queue: [],
        cursor: 0,
        track: nil
      }

      assert game.queue == []
      assert game.cursor == 0
    end

    test "can add players to queue" do
      game = %Game{
        id: "game-123",
        owner_id: "owner-456",
        max_participants: 10,
        max_score: 10,
        status: :waiting,
        participants: [],
        scores: %{},
        player: Player.new(),
        timelines: %{},
        created_at: DateTime.utc_now(),
        queue: [],
        cursor: 0,
        track: nil
      }

      updated_game = %{game | queue: ["player-1", "player-2"]}

      assert updated_game.queue == ["player-1", "player-2"]
    end

    test "cursor can be updated" do
      game = %Game{
        id: "game-123",
        owner_id: "owner-456",
        max_participants: 10,
        max_score: 10,
        status: :waiting,
        participants: [],
        scores: %{},
        player: Player.new(),
        timelines: %{},
        created_at: DateTime.utc_now(),
        queue: ["player-1", "player-2", "player-3"],
        cursor: 0,
        track: nil
      }

      updated_game = %{game | cursor: 1}

      assert updated_game.cursor == 1
      assert Enum.at(updated_game.queue, updated_game.cursor) == "player-2"
    end
  end

  describe "track field" do
    test "initializes with nil track" do
      game = %Game{
        id: "game-123",
        owner_id: "owner-456",
        max_participants: 10,
        max_score: 10,
        status: :waiting,
        participants: [],
        scores: %{},
        player: Player.new(),
        timelines: %{},
        created_at: DateTime.utc_now(),
        queue: [],
        cursor: 0,
        track: nil
      }

      assert is_nil(game.track)
    end

    test "can set track" do
      track = %Track{id: "track-1", title: "Song", artist: "Artist", year: 2020}

      game = %Game{
        id: "game-123",
        owner_id: "owner-456",
        max_participants: 10,
        max_score: 10,
        status: :waiting,
        participants: [],
        scores: %{},
        player: Player.new(),
        timelines: %{},
        created_at: DateTime.utc_now(),
        queue: [],
        cursor: 0,
        track: track
      }

      assert game.track == track
      assert game.track.title == "Song"
    end
  end

  describe "JSON encoding" do
    test "encodes with only allowed fields including queue, cursor, track" do
      track = %Track{id: "track-1", title: "Song", artist: "Artist", year: 2020}

      game = %Game{
        id: "game-123",
        owner_id: "owner-456",
        max_participants: 10,
        max_score: 10,
        status: :in_progress,
        participants: [],
        scores: %{},
        player: Player.new(),
        timelines: %{},
        created_at: DateTime.utc_now(),
        queue: ["player-1"],
        cursor: 0,
        track: track
      }

      json = Jason.encode!(game)
      decoded = Jason.decode!(json)

      assert decoded["id"] == "game-123"
      assert decoded["status"] == "in_progress"
      assert decoded["queue"] == ["player-1"]
      assert decoded["cursor"] == 0
      assert is_map(decoded["track"])
      assert decoded["track"]["title"] == "Song"
    end
  end
end
