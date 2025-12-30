defmodule Songy.Core.GameTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Game
  alias Songy.Core.Player
  alias Songy.Core.Track
  alias Songy.Core.User

  describe "struct" do
    test "creates game with required fields" do
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

  describe "validations" do
    defp base_game(overrides) do
      struct!(
        Game,
        Map.merge(
          %{
            id: "game-123",
            owner_id: "owner-456",
            max_participants: 2,
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
          },
          overrides
        )
      )
    end

    test "validate_not_full returns :ok when below capacity" do
      user = %User{uuid: "user-1", name: "Player1"}
      game = base_game(%{participants: [user]})

      assert :ok = Game.validate_not_full(game)
    end

    test "validate_not_full returns error when at capacity" do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}
      game = base_game(%{participants: [user1, user2]})

      assert {:error, :game_full} = Game.validate_not_full(game)
    end

    test "validate_not_duplicate detects existing participant" do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}
      game = base_game(%{participants: [user1]})

      assert {:error, :already_joined} = Game.validate_not_duplicate(game, user1)
      assert :ok = Game.validate_not_duplicate(game, user2)
    end

    test "validate_min_participants requires at least two participants" do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      assert {:error, :insufficient_participants} =
               Game.validate_min_participants(base_game(%{participants: [user1]}))

      assert :ok = Game.validate_min_participants(base_game(%{participants: [user1, user2]}))
    end

    test "valid_assumption? verifies timeline order at position" do
      timeline = [
        %Track{id: "t1", title: "Song A", artist: "Artist", year: 2000},
        %Track{id: "t2", title: "Song B", artist: "Artist", year: 2010},
        %Track{id: "t3", title: "Song C", artist: "Artist", year: 2020}
      ]

      bad_timeline = [
        %Track{id: "t1", title: "Song A", artist: "Artist", year: 2000},
        %Track{id: "t2", title: "Song B", artist: "Artist", year: 2020},
        %Track{id: "t3", title: "Song C", artist: "Artist", year: 2010}
      ]

      assert Game.valid_assumption?(timeline, 1)
      refute Game.valid_assumption?(bad_timeline, 1)
      refute Game.valid_assumption?(timeline, 99)
    end
  end

  describe "check_winner" do
    test "returns :no_winner when scores are empty" do
      assert :no_winner =
               Game.check_winner(
                 struct!(
                   Game,
                   %{
                     id: "game-123",
                     owner_id: "owner-456",
                     max_participants: 2,
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
                 )
               )
    end

    test "returns :no_winner when no one reached max score" do
      assert :no_winner =
               Game.check_winner(
                 struct!(
                   Game,
                   %{
                     id: "game-123",
                     owner_id: "owner-456",
                     max_participants: 2,
                     max_score: 10,
                     status: :waiting,
                     participants: [],
                     scores: %{"user-1" => 9},
                     player: Player.new(),
                     timelines: %{},
                     created_at: DateTime.utc_now(),
                     queue: [],
                     cursor: 0,
                     track: nil
                   }
                 )
               )
    end

    test "returns winner when someone reaches max score" do
      assert {:winner, "user-1"} =
               Game.check_winner(
                 struct!(
                   Game,
                   %{
                     id: "game-123",
                     owner_id: "owner-456",
                     max_participants: 2,
                     max_score: 10,
                     status: :waiting,
                     participants: [],
                     scores: %{"user-1" => 10},
                     player: Player.new(),
                     timelines: %{},
                     created_at: DateTime.utc_now(),
                     queue: [],
                     cursor: 0,
                     track: nil
                   }
                 )
               )
    end
  end

  describe "validate playback permission" do
    defp game_with_queue(queue, cursor \\ 0) do
      struct!(
        Game,
        %{
          id: "game-123",
          owner_id: "owner-456",
          max_participants: 4,
          max_score: 10,
          status: :in_progress,
          participants: [],
          scores: %{},
          player: Player.new(),
          timelines: %{},
          created_at: DateTime.utc_now(),
          queue: queue,
          cursor: cursor,
          track: nil
        }
      )
    end

    test "returns :unauthorized when user_id is nil" do
      game = game_with_queue(["player-1", "player-2"])

      assert {:error, :unauthorized} = Game.validate_playback_permission(game, nil)
    end

    test "returns :ok when user_id matches owner_id" do
      game = game_with_queue(["player-1", "player-2"])

      assert :ok = Game.validate_playback_permission(game, "owner-456")
    end

    test "returns :ok when user_id matches active player (cursor position)" do
      game = game_with_queue(["player-1", "player-2", "player-3"], 1)

      assert :ok = Game.validate_playback_permission(game, "player-2")
    end

    test "returns :unauthorized when user_id is not owner or active player" do
      game = game_with_queue(["player-1", "player-2", "player-3"], 0)

      assert {:error, :unauthorized} = Game.validate_playback_permission(game, "player-2")
    end

    test "returns :ok for owner even if owner is not in queue" do
      game = game_with_queue(["player-1", "player-2"])

      assert :ok = Game.validate_playback_permission(game, "owner-456")
    end

    test "returns :ok when cursor is at different positions" do
      queue = ["user-1", "user-2", "user-3", "user-4"]

      assert :ok = Game.validate_playback_permission(game_with_queue(queue, 0), "user-1")
      assert :ok = Game.validate_playback_permission(game_with_queue(queue, 1), "user-2")
      assert :ok = Game.validate_playback_permission(game_with_queue(queue, 2), "user-3")
      assert :ok = Game.validate_playback_permission(game_with_queue(queue, 3), "user-4")
    end

    test "returns :unauthorized for inactive players in queue" do
      queue = ["user-1", "user-2", "user-3", "user-4"]
      game = game_with_queue(queue, 1)

      assert {:error, :unauthorized} = Game.validate_playback_permission(game, "user-1")
      assert {:error, :unauthorized} = Game.validate_playback_permission(game, "user-3")
      assert {:error, :unauthorized} = Game.validate_playback_permission(game, "user-4")
    end

    test "returns :unauthorized when queue is empty" do
      game = game_with_queue([], 0)

      assert {:error, :unauthorized} = Game.validate_playback_permission(game, "player-1")
    end

    test "returns :ok when owner is also the active player" do
      game = game_with_queue(["owner-456", "player-2"], 0)

      assert :ok = Game.validate_playback_permission(game, "owner-456")
    end

    test "returns :unauthorized for cursor position beyond queue length" do
      game = game_with_queue(["player-1", "player-2"], 5)

      assert {:error, :unauthorized} = Game.validate_playback_permission(game, "player-1")
    end
  end
end
