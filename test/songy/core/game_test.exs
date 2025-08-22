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
      assert Game.get_active_player(updated_game) == user.uuid
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

  describe "update_status/1" do
    test "advances from waiting to in_progress" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      assert {:ok, updated_game} = Game.update_status(game)
      assert updated_game.status == :in_progress
    end

    test "advances from in_progress to finished" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      {:ok, in_progress_game} = Game.update_status(game)
      assert {:ok, finished_game} = Game.update_status(in_progress_game)
      assert finished_game.status == :finished
    end

    test "rejects advancing finished game" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      {:ok, in_progress_game} = Game.update_status(game)
      {:ok, finished_game} = Game.update_status(in_progress_game)

      assert {:error, :game_already_finished} = Game.update_status(finished_game)
    end

    test "full lifecycle progression" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      # waiting -> in_progress
      assert {:ok, in_progress_game} = Game.update_status(game)
      assert in_progress_game.status == :in_progress

      # in_progress -> finished
      assert {:ok, finished_game} = Game.update_status(in_progress_game)
      assert finished_game.status == :finished

      # finished -> error
      assert {:error, :game_already_finished} = Game.update_status(finished_game)
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

  describe "init_user_timeline/3" do
    test "initializes user timeline with single track" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track = Track.new(title: "Initial Song", artist: "Initial Artist", year: 2023)

      updated_game = Game.init_user_timeline(game, "user456", track)

      assert Game.get_user_timeline(updated_game, "user456") == [track]
      assert updated_game.uuid == game.uuid
      assert updated_game.timelines == %{"user456" => [track]}
    end

    test "replaces existing timeline with new track" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      # First, add some tracks to a timeline using old extend style for setup
      existing_track1 = Track.new(title: "Existing 1", artist: "Artist", year: 2020)
      existing_track2 = Track.new(title: "Existing 2", artist: "Artist", year: 2021)

      {:ok, game_with_track1} = Game.set_turn_track(game, existing_track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, "user456")

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, existing_track2)
      game_with_tracks = Game.extend_user_timeline(game_with_track2, "user456")

      # Now initialize with a new track - should replace the entire timeline
      init_track = Track.new(title: "New Initial", artist: "New Artist", year: 2023)
      updated_game = Game.init_user_timeline(game_with_tracks, "user456", init_track)

      assert Game.get_user_timeline(updated_game, "user456") == [init_track]
      assert length(Game.get_user_timeline(updated_game, "user456")) == 1
    end

    test "initializes multiple users independently" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "User1 Song", artist: "Artist1", year: 2023)
      track2 = Track.new(title: "User2 Song", artist: "Artist2", year: 2024)

      game_with_user1 = Game.init_user_timeline(game, "user1", track1)
      game_with_both = Game.init_user_timeline(game_with_user1, "user2", track2)

      assert Game.get_user_timeline(game_with_both, "user1") == [track1]
      assert Game.get_user_timeline(game_with_both, "user2") == [track2]
      assert map_size(game_with_both.timelines) == 2
    end
  end

  describe "extend_user_timeline/4" do
    test "adds track to user timeline" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2023)

      {:ok, game_with_track} = Game.set_turn_track(game, track)
      updated_game = Game.extend_user_timeline(game_with_track, "user456")

      assert Game.get_user_timeline(updated_game, "user456") == [track]
      # other fields preserved
      assert updated_game.uuid == game.uuid
    end

    test "adds multiple tracks to user timeline" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_first = Game.extend_user_timeline(game_with_track1, "user456")

      {:ok, game_with_track2} = Game.set_turn_track(game_with_first, track2)
      game_with_both = Game.extend_user_timeline(game_with_track2, "user456")

      # tracks are added to front of list
      assert Game.get_user_timeline(game_with_both, "user456") == [track2, track1]
    end

    test "manages tracks for different users separately" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_user1 = Game.extend_user_timeline(game_with_track1, "user1")

      {:ok, game_with_track2} = Game.set_turn_track(game_with_user1, track2)
      game_updated = Game.extend_user_timeline(game_with_track2, "user2")

      assert Game.get_user_timeline(game_updated, "user1") == [track1]
      assert Game.get_user_timeline(game_updated, "user2") == [track2]
    end

    test "adds track to head with position: 0" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_first = Game.extend_user_timeline(game_with_track1, "user456")

      {:ok, game_with_track2} = Game.set_turn_track(game_with_first, track2)
      game_with_both = Game.extend_user_timeline(game_with_track2, "user456", 0)

      assert Game.get_user_timeline(game_with_both, "user456") == [track2, track1]
    end

    test "adds track to specific position in timeline" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)
      track3 = Track.new(title: "Song 3", artist: "Artist 3", year: 2025)

      # Build initial timeline
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, "user456")

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game_with_timeline = Game.extend_user_timeline(game_with_track2, "user456")

      # Insert track3 at position 1 (between track2 and track1)
      {:ok, game_with_track3} = Game.set_turn_track(game_with_timeline, track3)
      updated_game = Game.extend_user_timeline(game_with_track3, "user456", 1)

      assert Game.get_user_timeline(updated_game, "user456") == [track2, track3, track1]
    end

    test "adds track at end when position equals list length" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)
      track3 = Track.new(title: "Song 3", artist: "Artist 3", year: 2025)

      # Build initial timeline
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, "user456")

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game_with_timeline = Game.extend_user_timeline(game_with_track2, "user456")

      # Insert at position 2 (at the end of 2-element list)
      {:ok, game_with_track3} = Game.set_turn_track(game_with_timeline, track3)
      updated_game = Game.extend_user_timeline(game_with_track3, "user456", 2)

      assert Game.get_user_timeline(updated_game, "user456") == [track2, track1, track3]
    end

    test "adds track at end when position is greater than list length" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist 1", year: 2023)
      track2 = Track.new(title: "Song 2", artist: "Artist 2", year: 2024)

      # Build initial timeline
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_first = Game.extend_user_timeline(game_with_track1, "user456")

      # Insert at position 999 (much greater than list length of 1)
      {:ok, game_with_track2} = Game.set_turn_track(game_with_first, track2)
      updated_game = Game.extend_user_timeline(game_with_track2, "user456", 999)

      assert Game.get_user_timeline(updated_game, "user456") == [track1, track2]
    end

    test "validates position argument types" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2023)

      # Set up the game with track for testing
      {:ok, game_with_track} = Game.set_turn_track(game, track)

      # Invalid position type should raise FunctionClauseError (guard failure)
      assert_raise FunctionClauseError, fn ->
        Game.extend_user_timeline(game_with_track, "user456", "invalid")
      end

      assert_raise FunctionClauseError, fn ->
        Game.extend_user_timeline(game_with_track, "user456", -1)
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
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game = Game.extend_user_timeline(game_with_track1, "user456")

      # Insert at position 0: [track2, track1]
      {:ok, game_with_track2} = Game.set_turn_track(game, track2)
      game = Game.extend_user_timeline(game_with_track2, "user456", 0)

      # Insert at position 2 (end): [track2, track1, track3]
      {:ok, game_with_track3} = Game.set_turn_track(game, track3)
      game = Game.extend_user_timeline(game_with_track3, "user456", 2)

      # Insert at position 1: [track2, track4, track1, track3]
      {:ok, game_with_track4} = Game.set_turn_track(game, track4)
      game = Game.extend_user_timeline(game_with_track4, "user456", 1)

      # Insert at position 999 (end): [track2, track4, track1, track3, track5]
      {:ok, game_with_track5} = Game.set_turn_track(game, track5)
      game = Game.extend_user_timeline(game_with_track5, "user456", 999)

      expected = [track2, track4, track1, track3, track5]
      assert Game.get_user_timeline(game, "user456") == expected
    end
  end

  describe "extend_active_timeline/3" do
    test "adds track to turn timeline at head by default and records assumption" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track = Track.new(title: "Song", artist: "Artist", year: 2023)
      {:ok, game_with_track} = Game.set_turn_track(game, track)

      updated_game = Game.extend_active_timeline(game_with_track, "user123")

      assert updated_game.turn.timeline == [track]
      assert updated_game.turn.assumptions == [%{position: 0, user_id: "user123"}]
    end

    test "adds multiple tracks to turn timeline and accumulates assumptions" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_first = Game.extend_active_timeline(game_with_track1, "user123")
      {:ok, game_with_track2} = Game.set_turn_track(game_with_first, track2)
      game_with_both = Game.extend_active_timeline(game_with_track2, "user456")

      assert game_with_both.turn.timeline == [track2, track1]
      assert game_with_both.turn.assumptions == [
        %{position: 1, user_id: "user123"},
        %{position: 0, user_id: "user456"}
      ]
    end

    test "adds track to head with position: 0 and records assumption" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_first = Game.extend_active_timeline(game_with_track1, "user123")
      {:ok, game_with_track2} = Game.set_turn_track(game_with_first, track2)
      game_with_both = Game.extend_active_timeline(game_with_track2, "user456", 0)

      assert game_with_both.turn.timeline == [track2, track1]
      assert game_with_both.turn.assumptions == [
        %{position: 1, user_id: "user123"},
        %{position: 0, user_id: "user456"}
      ]
    end

    test "adds track to specific position in timeline and records assumption" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      # Build initial timeline with track1 and track2
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_first = Game.extend_active_timeline(game_with_track1, "user123")
      {:ok, game_with_track2} = Game.set_turn_track(game_with_first, track2)
      game_with_timeline = Game.extend_active_timeline(game_with_track2, "user456")

      # Add track3 at position 1
      {:ok, game_with_track3} = Game.set_turn_track(game_with_timeline, track3)
      updated_game = Game.extend_active_timeline(game_with_track3, "user789", 1)

      assert updated_game.turn.timeline == [track2, track3, track1]

      assert updated_game.turn.assumptions == [
               %{position: 2, user_id: "user123"},
               %{position: 0, user_id: "user456"},
               %{position: 1, user_id: "user789"}
             ]
    end

    test "adds track at end when position equals list length and records assumption" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      # Build initial timeline with track1 and track2
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_first = Game.extend_active_timeline(game_with_track1, "user123")
      {:ok, game_with_track2} = Game.set_turn_track(game_with_first, track2)
      game_with_timeline = Game.extend_active_timeline(game_with_track2, "user456")

      # Add track3 at position 2 (end of list)
      {:ok, game_with_track3} = Game.set_turn_track(game_with_timeline, track3)
      updated_game = Game.extend_active_timeline(game_with_track3, "user789", 2)

      assert updated_game.turn.timeline == [track2, track1, track3]

      assert updated_game.turn.assumptions == [
               %{position: 1, user_id: "user123"},
               %{position: 0, user_id: "user456"},
               %{position: 2, user_id: "user789"}
             ]
    end

    test "adds track at end when position is greater than list length and records assumption" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_first = Game.extend_active_timeline(game_with_track1, "user123")

      {:ok, game_with_track2} = Game.set_turn_track(game_with_first, track2)
      updated_game = Game.extend_active_timeline(game_with_track2, "user456", 999)

      assert updated_game.turn.timeline == [track1, track2]
      assert updated_game.turn.assumptions == [%{position: 0, user_id: "user123"}, %{position: 1, user_id: "user456"}]
    end

    test "validates position argument types" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      track = Track.new(title: "Song", artist: "Artist", year: 2023)
      {:ok, game_with_track} = Game.set_turn_track(game, track)

      assert_raise FunctionClauseError, fn ->
        Game.extend_active_timeline(game_with_track, "user123", "invalid")
      end

      assert_raise FunctionClauseError, fn ->
        Game.extend_active_timeline(game_with_track, "user123", -1)
      end
    end

    test "supports multiple position options scenarios and accumulates assumptions" do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      tracks =
        for i <- 1..5 do
          Track.new(title: "Song #{i}", artist: "Artist #{i}", year: 2020 + i)
        end

      [track1, track2, track3, track4, track5] = tracks

      # Build timeline: [track1]
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game = Game.extend_active_timeline(game_with_track1, "user1")

      # Insert at position 0: [track2, track1]
      {:ok, game_with_track2} = Game.set_turn_track(game, track2)
      game = Game.extend_active_timeline(game_with_track2, "user2", 0)

      # Insert at position 2 (end): [track2, track1, track3]
      {:ok, game_with_track3} = Game.set_turn_track(game, track3)
      game = Game.extend_active_timeline(game_with_track3, "user3", 2)

      # Insert at position 1: [track2, track4, track1, track3]
      {:ok, game_with_track4} = Game.set_turn_track(game, track4)
      game = Game.extend_active_timeline(game_with_track4, "user4", 1)

      # Insert at position 999 (end): [track2, track4, track1, track3, track5]
      {:ok, game_with_track5} = Game.set_turn_track(game, track5)
      game = Game.extend_active_timeline(game_with_track5, "user5", 999)

      expected = [track2, track4, track1, track3, track5]
      assert game.turn.timeline == expected

      expected_assumptions = [
        %{position: 2, user_id: "user1"},
        %{position: 0, user_id: "user2"},
        %{position: 3, user_id: "user3"},
        %{position: 1, user_id: "user4"},
        %{position: 4, user_id: "user5"}
      ]

      assert game.turn.assumptions == expected_assumptions
    end
  end

  describe "reorder_active_timeline/3" do
    setup do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)

      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      # Build initial active timeline: [track3, track2, track1] (newest first)
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_active_timeline(game_with_track1, "setup_user1")

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game_step2 = Game.extend_active_timeline(game_with_track2, "setup_user2")

      {:ok, game_with_track3} = Game.set_turn_track(game_step2, track3)
      final_game = Game.extend_active_timeline(game_with_track3, "setup_user3")

      %{game: final_game, track1: track1, track2: track2, track3: track3}
    end

    test "moves track to beginning of active timeline", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      # Move track1 to position 0: [track1, track3, track2]
      {:ok, updated_game} = Game.reorder_active_timeline(game, track1.id, 0)
      timeline = updated_game.turn.timeline

      assert timeline == [track1, track3, track2]
    end

    test "moves track to middle of active timeline", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      # Move track1 to position 1: [track3, track1, track2]
      {:ok, updated_game} = Game.reorder_active_timeline(game, track1.id, 1)
      timeline = updated_game.turn.timeline

      assert timeline == [track3, track1, track2]
    end

    test "moves track to end of active timeline", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      # Move track3 to position 2: [track2, track1, track3]
      {:ok, updated_game} = Game.reorder_active_timeline(game, track3.id, 2)
      timeline = updated_game.turn.timeline

      assert timeline == [track2, track1, track3]
    end

    test "handles position beyond active timeline length", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      # Move track1 to position 10 (beyond end) - should move to end
      {:ok, updated_game} = Game.reorder_active_timeline(game, track1.id, 10)
      timeline = updated_game.turn.timeline

      assert timeline == [track3, track2, track1]
    end

    test "returns error for non-existent track", %{game: game} do
      non_existent_id = "non_existent_track_id"

      result = Game.reorder_active_timeline(game, non_existent_id, 0)

      assert result == {:error, :track_not_found}
    end

    test "returns error when game has no turn", %{track1: track1} do
      provider = Provider.new(:spotify)
      game = Game.new("owner123", provider: provider)
      # Clear the turn to simulate no active turn
      game_without_turn = %{game | turn: nil}

      result = Game.reorder_active_timeline(game_without_turn, track1.id, 0)

      assert result == {:error, :no_turn}
    end

    test "moving track to same position leaves active timeline unchanged", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      # Move track2 to its current position (index 1)
      {:ok, updated_game} = Game.reorder_active_timeline(game, track2.id, 1)
      timeline = updated_game.turn.timeline

      assert timeline == [track3, track2, track1]
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

    test "creates timeline snapshot when transitioning from waiting to ready (start of turn)" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      # Add participants
      user1 = User.new()
      user2 = User.new()
      {:ok, game} = Game.add_participant(game, user1)
      {:ok, game} = Game.add_participant(game, user2)

      # Add tracks to first player's timeline
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      first_player_uuid = Turn.get_active_player(game.turn)

      # Build timeline using separate set_turn_track and extend_user_timeline calls
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, first_player_uuid)

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game_step2 = Game.extend_user_timeline(game_with_track2, first_player_uuid)

      {:ok, game_with_track3} = Game.set_turn_track(game_step2, track3)
      game = Game.extend_user_timeline(game_with_track3, first_player_uuid)

      # Move through complete first player's turn
      game =
        game
        # waiting -> ready
        |> Game.next_phase()
        # ready -> steady
        |> Game.next_phase()
        # steady -> challenging
        |> Game.next_phase()
        # challenging -> results
        |> Game.next_phase()

      assert game.turn.phase == :results
      # Snapshot of first player's timeline
      assert game.turn.timeline == [track3, track2, track1]

      # Transition to waiting should create snapshot for NEW player
      # results -> waiting (next player)
      updated_game = Game.next_phase(game)

      assert updated_game.turn.phase == :waiting
      # Should drop before new player's turn
      assert updated_game.turn.timeline == []

      # Current player should be second player now
      second_player_uuid = Turn.get_active_player(updated_game.turn)
      assert second_player_uuid != first_player_uuid
    end

    test "does not create snapshot without :waiting -> :ready phase transitions" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      # Add participants
      user1 = User.new()
      user2 = User.new()
      {:ok, game} = Game.add_participant(game, user1)
      {:ok, game} = Game.add_participant(game, user2)

      # Move to ready phase (creates snapshot)
      # waiting -> ready
      game = Game.next_phase(game)
      assert game.turn.phase == :ready
      original_timeline = game.turn.timeline

      # Move through other phases - no new snapshots should be created
      game =
        game
        # ready -> steady
        |> Game.next_phase()
        # steady -> challenging
        |> Game.next_phase()

      assert game.turn.phase == :challenging
      # Snapshot unchanged
      assert game.turn.timeline == original_timeline
    end

    test "handles empty timeline when creating snapshot" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      # Add participants
      user1 = User.new()
      user2 = User.new()
      {:ok, game} = Game.add_participant(game, user1)
      {:ok, game} = Game.add_participant(game, user2)

      # First player has no timeline tracks
      assert game.turn.phase == :waiting
      assert game.turn.timeline == []

      # Transition to ready should create empty snapshot
      # waiting -> ready
      updated_game = Game.next_phase(game)

      assert updated_game.turn.phase == :ready
      # Empty timeline snapshot
      assert updated_game.turn.timeline == []
    end

    test "snapshot reflects active player's timeline at start of their turn" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      # Add participants
      user1 = User.new()
      user2 = User.new()
      {:ok, game} = Game.add_participant(game, user1)
      {:ok, game} = Game.add_participant(game, user2)

      # Add tracks to first player's timeline
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)
      extra_track = Track.new(title: "Extra Song", artist: "Artist", year: 2023)

      first_player_uuid = Turn.get_active_player(game.turn)

      # Build timeline using separate set_turn_track and extend_user_timeline calls
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, first_player_uuid)

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game_step2 = Game.extend_user_timeline(game_with_track2, first_player_uuid)

      {:ok, game_with_track3} = Game.set_turn_track(game_step2, track3)
      game_step3 = Game.extend_user_timeline(game_with_track3, first_player_uuid)

      {:ok, game_with_extra} = Game.set_turn_track(game_step3, extra_track)
      game = Game.extend_user_timeline(game_with_extra, first_player_uuid)

      # Transition to ready should create snapshot of first player's timeline
      # waiting -> ready
      updated_game = Game.next_phase(game)

      # Snapshot should include all 4 tracks from first player
      assert length(updated_game.turn.timeline) == 4
      assert List.first(updated_game.turn.timeline).title == "Extra Song"
      assert Turn.get_active_player(updated_game.turn) == first_player_uuid
    end

    test "adding tracks after snapshot creation does not affect snapshot" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      # Add participants
      user1 = User.new()
      user2 = User.new()
      {:ok, game} = Game.add_participant(game, user1)
      {:ok, game} = Game.add_participant(game, user2)

      # Add tracks to first player's timeline
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      first_player_uuid = Turn.get_active_player(game.turn)

      # Build timeline using separate set_turn_track and extend_user_timeline calls
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, first_player_uuid)

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game_step2 = Game.extend_user_timeline(game_with_track2, first_player_uuid)

      {:ok, game_with_track3} = Game.set_turn_track(game_step2, track3)
      game = Game.extend_user_timeline(game_with_track3, first_player_uuid)

      original_timeline = [track3, track2, track1]

      # Create snapshot by transitioning to ready
      # waiting -> ready (creates snapshot)
      game = Game.next_phase(game)

      assert game.turn.timeline == original_timeline

      # Add track to first player after snapshot creation
      new_track = Track.new(title: "New Song", artist: "Artist", year: 2024)
      {:ok, game_with_new_track} = Game.set_turn_track(game, new_track)
      updated_game = Game.extend_user_timeline(game_with_new_track, first_player_uuid)

      # Snapshot should remain unchanged
      assert updated_game.turn.timeline == original_timeline
      # But user's actual timeline should be updated
      assert length(Game.get_user_timeline(updated_game, first_player_uuid)) == 4
    end

    test "new player gets snapshot created when their turn starts" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      # Add participants
      user1 = User.new()
      user2 = User.new()
      {:ok, game} = Game.add_participant(game, user1)
      {:ok, game} = Game.add_participant(game, user2)

      # Add tracks to second player before first player's turn
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)

      second_player_uuid = game.turn.queue |> Enum.at(1)

      # Build timeline for second player
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, second_player_uuid)

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game = Game.extend_user_timeline(game_with_track2, second_player_uuid)

      # Complete first player's turn
      game =
        game
        # waiting -> ready (first player snapshot created)
        |> Game.next_phase()
        # ready -> steady
        |> Game.next_phase()
        # steady -> challenging
        |> Game.next_phase()
        # challenging -> results
        |> Game.next_phase()

      # Transition to second player
      # results -> waiting (second player)
      game = Game.next_phase(game)

      assert game.turn.phase == :waiting
      assert Turn.get_active_player(game.turn) == second_player_uuid
      # No snapshot yet for new player
      assert game.turn.timeline == []

      # When second player's turn starts, snapshot should be created
      # waiting -> ready (second player snapshot)
      updated_game = Game.next_phase(game)

      assert updated_game.turn.phase == :ready
      # Snapshot of second player's timeline
      assert length(updated_game.turn.timeline) == 2
      assert Turn.get_active_player(updated_game.turn) == second_player_uuid
    end
  end

  describe "get_active_player/1" do
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

      assert Game.get_active_player(game) == "player-1"
    end

    test "returns nil when queue is empty" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      game = Game.new(owner_uuid, provider: provider)

      # Turn is already initialized with empty queue in Game.new()
      assert Game.get_active_player(game) == nil
    end
  end
end
