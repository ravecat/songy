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

    test "adds user to turn queue automatically" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      user = User.new()

      assert {:ok, updated_game} = Game.add_participant(game, user)
      assert length(updated_game.turn.queue) == 1
      assert hd(updated_game.turn.queue) == user.uuid
      assert Game.get_current_player(updated_game) == user.uuid
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

    test "removes user from turn queue automatically" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      user1 = User.new()
      user2 = User.new()

      {:ok, game} = Game.add_participant(game, user1)
      {:ok, game} = Game.add_participant(game, user2)

      # Both users should be in queue
      assert length(game.turn.queue) == 2
      assert user1.uuid in game.turn.queue
      assert user2.uuid in game.turn.queue

      # Remove one user
      assert {:ok, updated_game} = Game.remove_participant(game, user1.uuid)

      # Only one user should remain in queue
      assert length(updated_game.turn.queue) == 1
      assert user2.uuid in updated_game.turn.queue
      assert user1.uuid not in updated_game.turn.queue
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

  describe "update_provider/2" do
    test "updates provider for game" do
      old_provider = Provider.new(:spotify)
      new_provider = Provider.new(:spotify, %{device_id: "new-device"})

      game = Game.new("owner123", provider: old_provider)
      updated_game = Game.update_provider(game, new_provider)

      assert updated_game.provider == new_provider
      assert updated_game.uuid == game.uuid
    end
  end

  describe "get_provider/1" do
    test "returns provider for game" do
      provider = Provider.new(:spotify, %{device_id: "test-device"})
      game = Game.new("owner123", provider: provider)

      assert Game.get_provider(game) == provider
    end

    test "returns provider with different configurations" do
      provider1 = Provider.new(:spotify)
      provider2 = Provider.new(:spotify, %{device_id: "device123", access_token: "token456"})

      game1 = Game.new("owner123", provider: provider1)
      game2 = Game.new("owner456", provider: provider2)

      assert Game.get_provider(game1) == provider1
      assert Game.get_provider(game2) == provider2
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
      user = User.new()
      {:ok, updated_game} = Game.add_participant(game, user)

      assert Game.empty?(updated_game) == false
    end

    test "returns true after removing all participants" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      user = User.new()
      {:ok, game_with_user} = Game.add_participant(game, user)
      {:ok, game_without_user} = Game.remove_participant(game_with_user, user.uuid)

      assert Game.empty?(game_without_user) == true
    end
  end

  describe "add_track_to_user_timeline/4" do
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

  describe "get_user_timeline/2" do
    test "gets empty timeline for user without tracks" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      assert Game.get_user_timeline(game, "user456") == []
    end

    test "initializes with empty timelines" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      assert game.timelines == %{}
    end
  end

  describe "remove_track_from_user_timeline/3" do
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
  end

  describe "valid_timeline?/1" do
    test "returns true for empty timeline" do
      assert Game.valid_timeline?([]) == true
    end

    test "returns true for single track timeline" do
      track = Track.new(title: "Single Song", artist: "Artist", year: 2023)
      assert Game.valid_timeline?([track]) == true
    end

    test "returns true for chronologically ordered tracks" do
      tracks = [
        Track.new(title: "Old Song", artist: "Artist 1", year: 1990),
        Track.new(title: "Middle Song", artist: "Artist 2", year: 2000),
        Track.new(title: "New Song", artist: "Artist 3", year: 2020)
      ]

      assert Game.valid_timeline?(tracks) == true
    end

    test "returns true for tracks with equal years" do
      tracks = [
        Track.new(title: "Song A", artist: "Artist 1", year: 2000),
        Track.new(title: "Song B", artist: "Artist 2", year: 2000),
        Track.new(title: "Song C", artist: "Artist 3", year: 2000)
      ]

      assert Game.valid_timeline?(tracks) == true
    end

    test "returns true for non-decreasing years" do
      tracks = [
        Track.new(title: "Song 1", artist: "Artist", year: 1990),
        Track.new(title: "Song 2", artist: "Artist", year: 1990),
        Track.new(title: "Song 3", artist: "Artist", year: 2000),
        Track.new(title: "Song 4", artist: "Artist", year: 2000),
        Track.new(title: "Song 5", artist: "Artist", year: 2020)
      ]

      assert Game.valid_timeline?(tracks) == true
    end

    test "returns false for out-of-order tracks" do
      tracks = [
        Track.new(title: "New Song", artist: "Artist 1", year: 2020),
        Track.new(title: "Old Song", artist: "Artist 2", year: 1990)
      ]

      assert Game.valid_timeline?(tracks) == false
    end

    test "returns false when first violation found" do
      tracks = [
        Track.new(title: "Song 1", artist: "Artist", year: 1990),
        Track.new(title: "Song 2", artist: "Artist", year: 2000),
        # violation here
        Track.new(title: "Song 3", artist: "Artist", year: 1995),
        Track.new(title: "Song 4", artist: "Artist", year: 2020)
      ]

      assert Game.valid_timeline?(tracks) == false
    end

    test "handles mixed valid and invalid sequences" do
      # Valid start, then invalid
      tracks1 = [
        Track.new(title: "Song 1", artist: "Artist", year: 1990),
        Track.new(title: "Song 2", artist: "Artist", year: 2000),
        # invalid
        Track.new(title: "Song 3", artist: "Artist", year: 1980)
      ]

      assert Game.valid_timeline?(tracks1) == false

      # Invalid start
      tracks2 = [
        Track.new(title: "Song 1", artist: "Artist", year: 2000),
        # invalid immediately
        Track.new(title: "Song 2", artist: "Artist", year: 1990)
      ]

      assert Game.valid_timeline?(tracks2) == false
    end

    test "works with large timeline" do
      # Create 100 tracks in chronological order
      tracks =
        for year <- 1920..2020 do
          Track.new(title: "Song #{year}", artist: "Artist", year: year)
        end

      assert Game.valid_timeline?(tracks) == true

      # Same tracks but with one out of order
      invalid_tracks = List.replace_at(tracks, 50, Track.new(title: "Wrong", artist: "Artist", year: 1900))
      assert Game.valid_timeline?(invalid_tracks) == false
    end
  end

  describe "next_phase/1" do
    test "moves the turn to the next phase" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      # Set up game with turn
      user1 = User.new()
      user2 = User.new()
      user3 = User.new()
      {:ok, game} = Game.add_participant(game, user1)
      {:ok, game} = Game.add_participant(game, user2)
      {:ok, game} = Game.add_participant(game, user3)

      updated_game = Game.next_phase(game)

      refute updated_game.turn.phase == game.turn.phase
    end
  end

  describe "get_current_player/1" do
    test "returns current player from game turn" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      turn =
        Turn.new()
        |> Turn.add_player_to_queue("player-1")
        |> Turn.add_player_to_queue("player-2")
        |> Turn.add_player_to_queue("player-3")
        |> Turn.next_phase()

      game = %{game | turn: turn}

      assert Game.get_current_player(game) == "player-1"
    end

    test "returns nil when queue is empty" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      # Turn is already initialized with empty queue in Game.new()
      assert Game.get_current_player(game) == nil
    end
  end
end
