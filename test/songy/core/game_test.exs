defmodule Songy.Core.GameTest do
  use ExUnit.Case, async: true

  alias Songy.Core.{Game, User, Provider, Player, Turn, Track}

  describe "new/2" do
    test "creates game with required provider" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      assert %Game{} = game
      assert game.max_participants == 8
      assert game.participants == []
      assert game.status == :waiting
      assert game.owner_uuid == owner_uuid
      assert %Provider{id: :spotify} = game.provider
      assert %Player{is_playback: false} = game.player
      assert String.length(game.uuid) == 8
      assert %DateTime{} = game.created_at
    end

    test "creates game with custom max participants and provider" do
      owner_uuid = "owner456"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider, max_participants: 4)

      assert game.max_participants == 4
      assert game.owner_uuid == owner_uuid
      assert game.participants == []
      assert game.status == :waiting
      assert %Provider{id: :spotify} = game.provider
    end

    test "creates game with multiple options" do
      owner_uuid = "owner789"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider, max_participants: 12)

      assert game.max_participants == 12
      assert game.owner_uuid == owner_uuid
      assert game.participants == []
      assert game.status == :waiting
      assert %Provider{id: :spotify} = game.provider
    end

    test "creates game with empty options list" do
      owner_uuid = "owner000"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      assert game.max_participants == 8
      assert game.owner_uuid == owner_uuid
      assert game.participants == []
      assert game.status == :waiting
      assert %Provider{id: :spotify} = game.provider
    end

    test "raises error without provider" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123")
      end
    end

    test "raises error with invalid provider" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", provider: "invalid")
      end
    end

    test "raises error with nil provider" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", provider: nil)
      end
    end

    test "raises error with invalid max_participants" do
      provider = Provider.new(:spotify)

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", provider: provider, max_participants: 0)
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", provider: provider, max_participants: -1)
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", provider: provider, max_participants: "invalid")
      end
    end

    test "raises error with unknown options" do
      provider = Provider.new(:spotify)

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", provider: provider, created_at: DateTime.utc_now())
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", provider: provider, uuid: "custom_uuid")
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", provider: provider, unknown_field: "test")
      end
    end
  end

  describe "add_participant/2" do
    test "adds user to game successfully" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      user = User.new()

      assert {:ok, updated_game} = Game.add_participant(game, user)
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == user.uuid
      assert %Provider{id: :spotify} = updated_game.provider
    end

    test "returns error when game is full" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider, max_participants: 1)
      user1 = User.new()
      user2 = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user1)
      assert {:error, :game_full} = Game.add_participant(game_with_user, user2)
    end

    test "returns error when user already joined" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      assert {:error, :user_already_joined} = Game.add_participant(game_with_user, user)
    end
  end

  describe "remove_participant/2" do
    test "removes user from game successfully" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      assert {:ok, updated_game} = Game.remove_participant(game_with_user, user.uuid)
      assert length(updated_game.participants) == 0
      assert %Provider{id: :spotify} = updated_game.provider
    end

    test "returns error when user not found" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      assert {:error, :user_not_found} = Game.remove_participant(game, "non_existent_uuid")
    end
  end

  describe "participant_count/1" do
    test "returns 0 for empty game" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      assert Game.participant_count(game) == 0
    end

    test "returns correct count with participants" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      user1 = User.new()
      user2 = User.new()

      {:ok, game_with_one} = Game.add_participant(game, user1)
      assert Game.participant_count(game_with_one) == 1

      {:ok, game_with_two} = Game.add_participant(game_with_one, user2)
      assert Game.participant_count(game_with_two) == 2
    end
  end

  describe "full?/1" do
    test "returns false for empty game" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider, max_participants: 2)

      assert Game.full?(game) == false
    end

    test "returns false for partially filled game" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider, max_participants: 2)
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      assert Game.full?(game_with_user) == false
    end

    test "returns true for full game" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider, max_participants: 1)
      user = User.new()

      {:ok, full_game} = Game.add_participant(game, user)
      assert Game.full?(full_game) == true
    end
  end

  describe "update_status/2" do
    test "updates status to in_progress" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      updated_game = Game.update_status(game, :in_progress)
      assert updated_game.status == :in_progress
    end

    test "updates status to finished" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      updated_game = Game.update_status(game, :finished)
      assert updated_game.status == :finished
    end

    test "updates status back to waiting" do
      provider = Provider.new(:spotify)

      game =
        Game.new("owner123", provider: provider)
        |> Game.update_status(:in_progress)

      updated_game = Game.update_status(game, :waiting)
      assert updated_game.status == :waiting
    end
  end

  describe "owner?/2" do
    test "returns true when user is owner" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      assert Game.owner?(game, owner_uuid) == true
    end

    test "returns false when user is not owner" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      assert Game.owner?(game, "other456") == false
    end
  end

  describe "player field" do
    test "has player with default state" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      assert %Player{is_playback: false} = game.player
    end
  end

  describe "start_playback/1" do
    test "starts playback for the game" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      updated_game = Game.start_playback(game)

      assert updated_game.player.is_playback == true
    end

    test "works when playback is already started" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      game = Game.start_playback(game)

      updated_game = Game.start_playback(game)

      assert updated_game.player.is_playback == true
    end
  end

  describe "pause_playback/1" do
    test "stops playback for the game" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      game = Game.start_playback(game)

      updated_game = Game.pause_playback(game)

      assert updated_game.player.is_playback == false
    end

    test "works when playback is already stopped" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      updated_game = Game.pause_playback(game)

      assert updated_game.player.is_playback == false
    end
  end

  describe "toggle_playback/1" do
    test "toggles playback state from false to true" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      updated_game = Game.toggle_playback(game)

      assert updated_game.player.is_playback == true
    end

    test "toggles playback state from true to false" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      game_with_playback = Game.toggle_playback(game)

      updated_game = Game.toggle_playback(game_with_playback)

      assert updated_game.player.is_playback == false
    end
  end

  describe "empty?/1" do
    test "returns true for game with no participants" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      assert Game.empty?(game) == true
    end

    test "returns false for game with participants" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      user = User.get_user("user456")
      {:ok, updated_game} = Game.add_participant(game, user)

      assert Game.empty?(updated_game) == false
    end

    test "returns true after removing all participants" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      user = User.get_user("user456")
      {:ok, game_with_user} = Game.add_participant(game, user)
      {:ok, game_without_user} = Game.remove_participant(game_with_user, "user456")

      assert Game.empty?(game_without_user) == true
    end
  end

  describe "update_turn/2" do
    test "sets turn on game" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      turn = Turn.new(player_id: "player-1")

      updated_game = Game.update_turn(game, turn)

      assert updated_game.turn == turn
      # other fields preserved
      assert updated_game.uuid == game.uuid
    end

    test "replaces existing turn" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      old_turn = Turn.new(player_id: "player-old")
      new_turn = Turn.new(player_id: "player-new")

      game_with_old = Game.update_turn(game, old_turn)
      game_with_new = Game.update_turn(game_with_old, new_turn)

      assert game_with_new.turn == new_turn
      refute game_with_new.turn == old_turn
    end

    test "works with complete turn data" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      track =
        Track.new(
          title: "Test Song",
          artist: "Test Artist",
          year: 2023
        )

      turn =
        Turn.new(
          player_id: "player-1",
          challengers: ["challenger-1", "challenger-2"],
          track: track
        )

      updated_game = Game.update_turn(game, turn)

      assert updated_game.turn.player_id == "player-1"
      assert updated_game.turn.challengers == ["challenger-1", "challenger-2"]
      assert updated_game.turn.track == track
    end
  end

  describe "timelines management" do
    test "adds track to user timeline" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2023)

      updated_game = Game.add_track_to_user_timeline(game, "user456", track)

      assert Game.get_user_timeline(updated_game, "user456") == [track]
      # other fields preserved
      assert updated_game.uuid == game.uuid
    end

    test "adds multiple tracks to user timeline" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)

      game_with_first = Game.add_track_to_user_timeline(game, "user456", track1)
      game_with_both = Game.add_track_to_user_timeline(game_with_first, "user456", track2)

      # tracks are added to front of list
      assert Game.get_user_timeline(game_with_both, "user456") == [track2, track1]
    end

    test "manages tracks for different users separately" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)

      game_updated =
        game
        |> Game.add_track_to_user_timeline("user1", track1)
        |> Game.add_track_to_user_timeline("user2", track2)

      assert Game.get_user_timeline(game_updated, "user1") == [track1]
      assert Game.get_user_timeline(game_updated, "user2") == [track2]
    end

    test "gets empty timeline for user without tracks" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      assert Game.get_user_timeline(game, "user456") == []
    end

    test "removes track from user timeline" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2023)

      game_with_track = Game.add_track_to_user_timeline(game, "user456", track)
      game_without_track = Game.remove_track_from_user_timeline(game_with_track, "user456", track)

      assert Game.get_user_timeline(game_without_track, "user456") == []
    end

    test "removes specific track from timeline with multiple tracks" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)
      track3 = Track.new(title: "Song 3", artist: "Artist 3", year: 2025)

      game_with_timeline =
        game
        |> Game.add_track_to_user_timeline("user456", track1)
        |> Game.add_track_to_user_timeline("user456", track2)
        |> Game.add_track_to_user_timeline("user456", track3)

      updated_game = Game.remove_track_from_user_timeline(game_with_timeline, "user456", track2)

      # track2 removed, track3 and track1 remain in order
      assert Game.get_user_timeline(updated_game, "user456") == [track3, track1]
    end

    test "removing track from empty timeline leaves it empty" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2023)

      updated_game = Game.remove_track_from_user_timeline(game, "user456", track)
      assert Game.get_user_timeline(updated_game, "user456") == []
    end

    test "removing non-existent track leaves timeline unchanged" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)

      game_with_track = Game.add_track_to_user_timeline(game, "user456", track1)
      updated_game = Game.remove_track_from_user_timeline(game_with_track, "user456", track2)

      assert Game.get_user_timeline(updated_game, "user456") == [track1]
    end

    test "initializes with empty timelines" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      assert game.timelines == %{}
    end

    test "adds track to head with position: 0" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)

      game_with_first = Game.add_track_to_user_timeline(game, "user456", track1)
      game_with_both = Game.add_track_to_user_timeline(game_with_first, "user456", track2, position: 0)

      assert Game.get_user_timeline(game_with_both, "user456") == [track2, track1]
    end

    test "adds track to specific position in timeline" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)
      track3 = Track.new(title: "Song 3", artist: "Artist 3", year: 2025)

      game_with_timeline =
        game
        |> Game.add_track_to_user_timeline("user456", track1)
        |> Game.add_track_to_user_timeline("user456", track2)

      # Insert track3 at position 1 (between track2 and track1)
      updated_game = Game.add_track_to_user_timeline(game_with_timeline, "user456", track3, position: 1)

      assert Game.get_user_timeline(updated_game, "user456") == [track2, track3, track1]
    end

    test "adds track at end when position equals list length" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)
      track3 = Track.new(title: "Song 3", artist: "Artist 3", year: 2025)

      game_with_timeline =
        game
        |> Game.add_track_to_user_timeline("user456", track1)
        |> Game.add_track_to_user_timeline("user456", track2)

      # Insert at position 2 (at the end of 2-element list)
      updated_game = Game.add_track_to_user_timeline(game_with_timeline, "user456", track3, position: 2)

      assert Game.get_user_timeline(updated_game, "user456") == [track2, track1, track3]
    end

    test "adds track at end when position is greater than list length" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)

      game_with_first = Game.add_track_to_user_timeline(game, "user456", track1)

      # Insert at position 999 (much greater than list length of 1)
      updated_game = Game.add_track_to_user_timeline(game_with_first, "user456", track2, position: 999)

      assert Game.get_user_timeline(updated_game, "user456") == [track1, track2]
    end

    test "validates position option" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2023)

      # Invalid position type should raise error
      assert_raise NimbleOptions.ValidationError, fn ->
        Game.add_track_to_user_timeline(game, "user456", track, position: "invalid")
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.add_track_to_user_timeline(game, "user456", track, position: -1)
      end
    end

    test "supports multiple position options scenarios" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      tracks =
        for i <- 1..5 do
          Track.new(title: "Song #{i}", artist: "Artist #{i}", year: 2020 + i)
        end

      [track1, track2, track3, track4, track5] = tracks

      # Build timeline: [track1]
      game = Game.add_track_to_user_timeline(game, "user456", track1)

      # Insert at position 0: [track2, track1]
      game = Game.add_track_to_user_timeline(game, "user456", track2, position: 0)

      # Insert at position 2 (end): [track2, track1, track3]
      game = Game.add_track_to_user_timeline(game, "user456", track3, position: 2)

      # Insert at position 1: [track2, track4, track1, track3]
      game = Game.add_track_to_user_timeline(game, "user456", track4, position: 1)

      # Insert at position 999 (end): [track2, track4, track1, track3, track5]
      game = Game.add_track_to_user_timeline(game, "user456", track5, position: 999)

      expected = [track2, track4, track1, track3, track5]
      assert Game.get_user_timeline(game, "user456") == expected
    end
  end
end
