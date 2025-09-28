defmodule Songy.Core.GameTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Game
  alias Songy.Core.Track
  alias Songy.Core.Turn
  alias Songy.Core.User

  describe "new/2" do
    test "creates game with default options" do
      owner_uuid = "owner123"
      game = Game.new(owner_uuid)

      assert %Game{
               max_participants: 8,
               participants: [],
               status: :waiting,
               owner_uuid: ^owner_uuid
             } = game

      assert String.length(game.id) == 4
      assert %DateTime{} = game.created_at
    end

    test "creates game with custom max participants" do
      owner_uuid = "owner456"
      game = Game.new(owner_uuid, max_participants: 4)

      assert %Game{
               max_participants: 4,
               owner_uuid: ^owner_uuid,
               participants: [],
               status: :waiting
             } = game
    end

    test "creates game with multiple options" do
      owner_uuid = "owner789"
      game = Game.new(owner_uuid, max_participants: 12)

      assert %Game{
               max_participants: 12,
               owner_uuid: ^owner_uuid,
               participants: [],
               status: :waiting
             } = game
    end

    test "creates game with empty options list" do
      game = Game.new("owner000")

      assert %Game{
               max_participants: 8,
               owner_uuid: "owner000",
               participants: [],
               status: :waiting
             } = game
    end

    test "new game has empty scores" do
      game = Game.new("owner123")

      assert %Game{scores: %{}} = game
    end

    test "raises error with invalid max_participants" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", max_participants: 0)
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", max_participants: -1)
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", max_participants: "invalid")
      end
    end

    test "raises error with unknown options" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", created_at: DateTime.utc_now())
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", uuid: "custom_uuid")
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", unknown_field: "test")
      end
    end

    test "creates game with default max_score" do
      game = Game.new("owner123")

      assert %Game{max_score: 10} = game
    end

    test "creates game with custom max_score" do
      game = Game.new("owner123", max_score: 5)

      assert %Game{max_score: 5} = game
    end

    test "validates max_score is positive integer" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", max_score: 0)
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", max_score: -1)
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", max_score: "invalid")
      end
    end
  end

  describe "add_participant/2" do
    test "adds user to game successfully" do
      game = Game.new("owner123")
      user = User.new()

      assert {:ok, updated_game} = Game.add_participant(game, user)
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == user.uuid
    end

    test "adds user to turn queue automatically" do
      game = Game.new("owner123")
      user = User.new()

      assert {:ok, updated_game} = Game.add_participant(game, user)
      assert length(updated_game.turn.queue) == 1
      assert hd(updated_game.turn.queue) == user.uuid
      assert Game.get_active_player(updated_game) == user.uuid
    end

    test "returns error when game is full" do
      game = Game.new("owner123", max_participants: 1)
      user1 = User.new()
      user2 = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user1)
      assert {:error, :game_full} = Game.add_participant(game_with_user, user2)
    end

    test "returns error when user already joined" do
      game = Game.new("owner123")
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      assert {:error, :user_already_joined} = Game.add_participant(game_with_user, user)
    end

    test "add_participant initializes player score to 0" do
      game = Game.new("owner123")
      user = User.new()

      {:ok, updated_game} = Game.add_participant(game, user)

      assert Map.get(updated_game.scores, user.uuid, 0) == 0
      assert Map.has_key?(updated_game.scores, user.uuid)
    end
  end

  describe "remove_participant/2" do
    test "removes user from game successfully" do
      game = Game.new("owner123")
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      assert {:ok, updated_game} = Game.remove_participant(game_with_user, user.uuid)
      assert length(updated_game.participants) == 0
    end

    test "removes user from turn queue automatically" do
      game = Game.new("owner123")
      user1 = User.new()
      user2 = User.new()

      {:ok, game} = Game.add_participant(game, user1)
      {:ok, game} = Game.add_participant(game, user2)

      assert length(game.turn.queue) == 2
      assert user1.uuid in game.turn.queue
      assert user2.uuid in game.turn.queue

      assert {:ok, updated_game} = Game.remove_participant(game, user1.uuid)

      assert length(updated_game.turn.queue) == 1
      assert user2.uuid in updated_game.turn.queue
      assert user1.uuid not in updated_game.turn.queue
    end

    test "returns error when user not found" do
      game = Game.new("owner123")

      assert {:error, :user_not_found} = Game.remove_participant(game, "non_existent_uuid")
    end

    test "remove_participant preserves scores for reconnection" do
      game = Game.new("owner123")
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      game_with_score = Game.increment_user_score(game_with_user, user.uuid, 50)
      {:ok, game_after_removal} = Game.remove_participant(game_with_score, user.uuid)

      assert Map.get(game_after_removal.scores, user.uuid, 0) == 50
      assert Map.has_key?(game_after_removal.scores, user.uuid)
    end
  end

  describe "participant_count/1" do
    test "returns 0 for empty game" do
      game = Game.new("owner123")

      assert Game.participant_count(game) == 0
    end

    test "returns correct count with participants" do
      game = Game.new("owner123")
      user1 = User.new()
      user2 = User.new()

      {:ok, game_with_one} = Game.add_participant(game, user1)
      assert Game.participant_count(game_with_one) == 1

      {:ok, game_with_two} = Game.add_participant(game_with_one, user2)
      assert Game.participant_count(game_with_two) == 2
    end
  end

  describe "increment_user_score/2" do
    test "defaults to 1 point" do
      game = Game.new("owner123")
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      updated_game = Game.increment_user_score(game_with_user, user.uuid)

      assert Map.get(updated_game.scores, user.uuid, 0) == 1
    end

    test "works with default 1 point for multiple calls" do
      game = Game.new("owner123")
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)

      final_game =
        game_with_user
        |> Game.increment_user_score(user.uuid)
        |> Game.increment_user_score(user.uuid)
        |> Game.increment_user_score(user.uuid)

      assert Map.get(final_game.scores, user.uuid, 0) == 3
    end

    test "returns unchanged game for non-existent player" do
      game = Game.new("owner123")

      unchanged_game = Game.increment_user_score(game, "non_existent_uuid")

      assert unchanged_game == game
      assert Map.get(unchanged_game.scores, "non_existent_uuid", 0) == 0
    end
  end

  describe "increment_user_score/3" do
    test "accumulates points correctly with custom amount" do
      game = Game.new("owner123")
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      game_step1 = Game.increment_user_score(game_with_user, user.uuid, 30)
      game_step2 = Game.increment_user_score(game_step1, user.uuid, 20)

      assert Map.get(game_step2.scores, user.uuid, 0) == 50
    end

    test "returns unchanged game for non-existent player" do
      game = Game.new("owner123")

      unchanged_game = Game.increment_user_score(game, "non_existent_uuid", 10)

      assert unchanged_game == game
      assert Map.get(unchanged_game.scores, "non_existent_uuid", 0) == 0
    end
  end

  describe "full?/1" do
    test "returns false for empty game" do
      game = Game.new("owner123", max_participants: 2)

      assert Game.full?(game) == false
    end

    test "returns false for partially filled game" do
      game = Game.new("owner123", max_participants: 2)
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      assert Game.full?(game_with_user) == false
    end

    test "returns true for full game" do
      game = Game.new("owner123", max_participants: 1)
      user = User.new()

      {:ok, full_game} = Game.add_participant(game, user)
      assert Game.full?(full_game) == true
    end
  end

  describe "update_status/1" do
    test "advances from waiting to in_progress" do
      game = Game.new("owner123")

      assert {:ok, updated_game} = Game.update_status(game)
      assert updated_game.status == :in_progress
    end

    test "advances from in_progress to finished" do
      game = Game.new("owner123")

      {:ok, in_progress_game} = Game.update_status(game)
      assert {:ok, finished_game} = Game.update_status(in_progress_game)
      assert finished_game.status == :finished
    end

    test "rejects advancing finished game" do
      game = Game.new("owner123")

      {:ok, in_progress_game} = Game.update_status(game)
      {:ok, finished_game} = Game.update_status(in_progress_game)

      assert {:error, :game_already_finished} = Game.update_status(finished_game)
    end

    test "full lifecycle progression" do
      game = Game.new("owner123")

      assert {:ok, in_progress_game} = Game.update_status(game)
      assert in_progress_game.status == :in_progress

      assert {:ok, finished_game} = Game.update_status(in_progress_game)
      assert finished_game.status == :finished

      assert {:error, :game_already_finished} = Game.update_status(finished_game)
    end
  end

  describe "owner?/2" do
    test "returns true when user is owner" do
      owner_uuid = "owner123"

      game = Game.new(owner_uuid)

      assert Game.owner?(game, owner_uuid) == true
    end

    test "returns false when user is not owner" do
      game = Game.new("owner123")

      assert Game.owner?(game, "other456") == false
    end
  end

  describe "start_playback/1" do
    test "starts playback for the game" do
      game = Game.new("owner123")

      updated_game = Game.start_playback(game)

      assert updated_game.player.is_playback == true
    end

    test "works when playback is already started" do
      game = Game.new("owner123")
      game = Game.start_playback(game)

      updated_game = Game.start_playback(game)

      assert updated_game.player.is_playback == true
    end
  end

  describe "pause_playback/1" do
    test "stops playback for the game" do
      game = Game.new("owner123")
      game = Game.start_playback(game)

      updated_game = Game.pause_playback(game)

      assert updated_game.player.is_playback == false
    end

    test "works when playback is already stopped" do
      game = Game.new("owner123")

      updated_game = Game.pause_playback(game)

      assert updated_game.player.is_playback == false
    end
  end

  describe "toggle_playback/1" do
    test "toggles playback state from false to true" do
      game = Game.new("owner123")

      updated_game = Game.toggle_playback(game)

      assert updated_game.player.is_playback == true
    end

    test "toggles playback state from true to false" do
      game = Game.new("owner123")
      game_with_playback = Game.toggle_playback(game)

      updated_game = Game.toggle_playback(game_with_playback)

      assert updated_game.player.is_playback == false
    end
  end

  describe "empty?/1" do
    test "returns true for game with no participants" do
      game = Game.new("owner123")

      assert Game.empty?(game) == true
    end

    test "returns false for game with participants" do
      game = Game.new("owner123")
      user = User.new()
      {:ok, updated_game} = Game.add_participant(game, user)

      assert Game.empty?(updated_game) == false
    end

    test "returns true after removing all participants" do
      game = Game.new("owner123")
      user = User.new()
      {:ok, game_with_user} = Game.add_participant(game, user)
      {:ok, game_without_user} = Game.remove_participant(game_with_user, user.uuid)

      assert Game.empty?(game_without_user) == true
    end
  end

  describe "init_user_timeline/3" do
    test "initializes user timeline with single track" do
      game = Game.new("owner123")
      track = Track.new(title: "Initial Song", artist: "Initial Artist", year: 2023)

      updated_game = Game.init_user_timeline(game, "user456", track)

      assert Game.get_user_timeline(updated_game, "user456") == [track]
      assert updated_game.id == game.id
      assert updated_game.timelines == %{"user456" => [track]}
    end

    test "replaces existing timeline with new track" do
      game = Game.new("owner123")

      existing_track1 = Track.new(title: "Existing 1", artist: "Artist", year: 2020)
      existing_track2 = Track.new(title: "Existing 2", artist: "Artist", year: 2021)

      {:ok, game_with_track1} = Game.set_turn_track(game, existing_track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, "user456")

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, existing_track2)
      game_with_tracks = Game.extend_user_timeline(game_with_track2, "user456")

      init_track = Track.new(title: "New Initial", artist: "New Artist", year: 2023)
      updated_game = Game.init_user_timeline(game_with_tracks, "user456", init_track)

      assert Game.get_user_timeline(updated_game, "user456") == [init_track]
      assert length(Game.get_user_timeline(updated_game, "user456")) == 1
    end

    test "initializes multiple users independently" do
      game = Game.new("owner123")
      track1 = Track.new(title: "User1 Song", artist: "Artist1", year: 2023)
      track2 = Track.new(title: "User2 Song", artist: "Artist2", year: 2024)

      game_with_user1 = Game.init_user_timeline(game, "user1", track1)
      game_with_both = Game.init_user_timeline(game_with_user1, "user2", track2)

      assert Game.get_user_timeline(game_with_both, "user1") == [track1]
      assert Game.get_user_timeline(game_with_both, "user2") == [track2]
      assert map_size(game_with_both.timelines) == 2
    end
  end

  describe "extend_user_timeline/2" do
    test "adds track to user timeline in chronological order" do
      game = Game.new("owner123")
      track = Track.new(title: "Test Song", artist: "Test Artist", year: 2023)

      {:ok, game_with_track} = Game.set_turn_track(game, track)
      updated_game = Game.extend_user_timeline(game_with_track, "user456")

      assert Game.get_user_timeline(updated_game, "user456") == [track]
      assert updated_game.id == game.id
    end

    test "maintains chronological order when adding multiple tracks" do
      game = Game.new("owner123")

      # Add tracks in non-chronological order to test automatic positioning
      track_2023 = Track.new(title: "Song 2023", artist: "Artist", year: 2023)
      track_2020 = Track.new(title: "Song 2020", artist: "Artist", year: 2020)
      track_2025 = Track.new(title: "Song 2025", artist: "Artist", year: 2025)

      # Add 2023 track first
      {:ok, game_with_track1} = Game.set_turn_track(game, track_2023)
      game_step1 = Game.extend_user_timeline(game_with_track1, "user456")

      # Add 2020 track - should be positioned before 2023
      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track_2020)
      game_step2 = Game.extend_user_timeline(game_with_track2, "user456")

      # Add 2025 track - should be positioned after 2023
      {:ok, game_with_track3} = Game.set_turn_track(game_step2, track_2025)
      final_game = Game.extend_user_timeline(game_with_track3, "user456")

      # Should be in chronological order: 2020, 2023, 2025
      timeline = Game.get_user_timeline(final_game, "user456")
      assert timeline == [track_2020, track_2023, track_2025]
    end

    test "maintains stable sort for tracks with same year" do
      game = Game.new("owner123")

      track1 = Track.new(title: "Song A", artist: "Artist A", year: 2023)
      track2 = Track.new(title: "Song B", artist: "Artist B", year: 2023)

      # Add both tracks with same year
      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, "user456")

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game_step2 = Game.extend_user_timeline(game_with_track2, "user456")

      timeline = Game.get_user_timeline(game_step2, "user456")
      # First added track should remain first for same year (stable sort)
      assert timeline == [track1, track2]
    end
  end

  describe "extend_active_timeline/3" do
    test "adds track to turn timeline at head by default and records assumption" do
      game = Game.new("owner123")
      track = Track.new(title: "Song", artist: "Artist", year: 2023)
      {:ok, game_with_track} = Game.set_turn_track(game, track)

      updated_game = Game.extend_active_timeline(game_with_track, "user123")

      assert updated_game.turn.timeline == [track]
      assert updated_game.turn.assumptions == [%{position: 0, user_id: "user123"}]
    end

    test "adds multiple tracks to turn timeline and accumulates assumptions" do
      game = Game.new("owner123")
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
      game = Game.new("owner123")
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
      game = Game.new("owner123")
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_first = Game.extend_active_timeline(game_with_track1, "user123")
      {:ok, game_with_track2} = Game.set_turn_track(game_with_first, track2)
      game_with_timeline = Game.extend_active_timeline(game_with_track2, "user456")

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
      game = Game.new("owner123")
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_with_first = Game.extend_active_timeline(game_with_track1, "user123")
      {:ok, game_with_track2} = Game.set_turn_track(game_with_first, track2)
      game_with_timeline = Game.extend_active_timeline(game_with_track2, "user456")

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
      game = Game.new("owner123")
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
      game = Game.new("owner123")
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
      game = Game.new("owner123")

      tracks =
        for i <- 1..5 do
          Track.new(title: "Song #{i}", artist: "Artist #{i}", year: 2020 + i)
        end

      [track1, track2, track3, track4, track5] = tracks

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game = Game.extend_active_timeline(game_with_track1, "user1")

      {:ok, game_with_track2} = Game.set_turn_track(game, track2)
      game = Game.extend_active_timeline(game_with_track2, "user2", 0)

      {:ok, game_with_track3} = Game.set_turn_track(game, track3)
      game = Game.extend_active_timeline(game_with_track3, "user3", 2)

      {:ok, game_with_track4} = Game.set_turn_track(game, track4)
      game = Game.extend_active_timeline(game_with_track4, "user4", 1)

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
      game = Game.new("owner123")

      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

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
      {:ok, updated_game} = Game.reorder_active_timeline(game, "setup_user1", 0)
      timeline = updated_game.turn.timeline

      assert timeline == [track1, track3, track2]
    end

    test "moves track to middle of active timeline", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      {:ok, updated_game} = Game.reorder_active_timeline(game, "setup_user1", 1)
      timeline = updated_game.turn.timeline

      assert timeline == [track3, track1, track2]
    end

    test "moves track to end of active timeline", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      {:ok, updated_game} = Game.reorder_active_timeline(game, "setup_user3", 2)
      timeline = updated_game.turn.timeline

      assert timeline == [track2, track1, track3]
    end

    test "handles position beyond active timeline length", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      {:ok, updated_game} = Game.reorder_active_timeline(game, "setup_user1", 10)
      timeline = updated_game.turn.timeline

      assert timeline == [track3, track2, track1]
    end

    test "returns error for non-existent user", %{game: game} do
      non_existent_user = "non_existent_user_uuid"

      result = Game.reorder_active_timeline(game, non_existent_user, 0)

      assert result == {:error, :user_assumption_not_found}
    end

    test "returns error when game has no turn" do
      game = Game.new("owner123")
      game_without_turn = %{game | turn: nil}

      result = Game.reorder_active_timeline(game_without_turn, "setup_user1", 0)

      assert result == {:error, :no_turn}
    end

    test "moving track to same position leaves active timeline unchanged", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      {:ok, updated_game} = Game.reorder_active_timeline(game, "setup_user2", 1)
      timeline = updated_game.turn.timeline

      assert timeline == [track3, track2, track1]
    end

    test "properly synchronizes assumptions when reordering tracks", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      {:ok, updated_game} = Game.reorder_active_timeline(game, "setup_user1", 0)
      timeline = updated_game.turn.timeline
      assumptions = updated_game.turn.assumptions

      assert timeline == [track1, track3, track2]

      expected_assumptions = [
        %{position: 0, user_id: "setup_user1"},
        %{position: 1, user_id: "setup_user3"},
        %{position: 2, user_id: "setup_user2"}
      ]

      sorted_assumptions = Enum.sort_by(assumptions, & &1.position)
      sorted_expected = Enum.sort_by(expected_assumptions, & &1.position)

      assert sorted_assumptions == sorted_expected
    end

    test "properly synchronizes assumptions when moving track right", %{
      game: game,
      track1: track1,
      track2: track2,
      track3: track3
    } do
      {:ok, updated_game} = Game.reorder_active_timeline(game, "setup_user3", 2)
      timeline = updated_game.turn.timeline
      assumptions = updated_game.turn.assumptions

      assert timeline == [track2, track1, track3]

      expected_assumptions = [
        %{position: 0, user_id: "setup_user2"},
        %{position: 1, user_id: "setup_user1"},
        %{position: 2, user_id: "setup_user3"}
      ]

      sorted_assumptions = Enum.sort_by(assumptions, & &1.position)
      sorted_expected = Enum.sort_by(expected_assumptions, & &1.position)

      assert sorted_assumptions == sorted_expected
    end
  end

  describe "get_user_timeline/2" do
    test "gets empty timeline for user without tracks" do
      game = Game.new("owner123")

      assert Game.get_user_timeline(game, "user456") == []
    end

    test "initializes with empty timelines" do
      game = Game.new("owner123")

      assert game.timelines == %{}
    end
  end

  describe "next_phase/1" do
    setup do
      game = Game.new("owner123")

      user1 = User.new()
      user2 = User.new()
      user3 = User.new()
      {:ok, game} = Game.add_participant(game, user1)
      {:ok, game} = Game.add_participant(game, user2)
      {:ok, game} = Game.add_participant(game, user3)

      %{game: game, user1: user1, user2: user2, user3: user3}
    end

    test "moves the turn to the next phase", %{game: game} do
      updated_game = Game.next_phase(game)

      refute updated_game.turn.phase == game.turn.phase
    end

    test "creates timeline snapshot when transitioning from waiting to ready (start of turn)", %{game: game} do
      first_player_uuid = Turn.get_active_player(game.turn)

      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, first_player_uuid)

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game_step2 = Game.extend_user_timeline(game_with_track2, first_player_uuid)

      {:ok, game_with_track3} = Game.set_turn_track(game_step2, track3)
      game = Game.extend_user_timeline(game_with_track3, first_player_uuid)

      game =
        game
        |> Game.next_phase()
        |> Game.next_phase()
        |> Game.next_phase()
        |> Game.next_phase()

      assert game.turn.phase == :results
      assert game.turn.timeline == [track1, track2, track3]

      updated_game = Game.next_phase(game)

      assert updated_game.turn.phase == :waiting
      assert updated_game.turn.timeline == []

      second_player_uuid = Turn.get_active_player(updated_game.turn)
      assert second_player_uuid != first_player_uuid
    end

    test "does not create snapshot without :waiting -> :ready phase transitions", %{game: game} do
      game = Game.next_phase(game)
      assert game.turn.phase == :ready
      original_timeline = game.turn.timeline

      game =
        game
        |> Game.next_phase()
        |> Game.next_phase()

      assert game.turn.phase == :challenging
      assert game.turn.timeline == original_timeline
    end

    test "handles empty timeline when creating snapshot", %{game: game} do
      assert game.turn.phase == :waiting
      assert game.turn.timeline == []

      updated_game = Game.next_phase(game)

      assert updated_game.turn.phase == :ready
      assert updated_game.turn.timeline == []
    end

    test "reflects active player's timeline at start of their turn", %{game: game} do
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)
      extra_track = Track.new(title: "Extra Song", artist: "Artist", year: 2023)

      first_player_uuid = Turn.get_active_player(game.turn)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, first_player_uuid)

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game_step2 = Game.extend_user_timeline(game_with_track2, first_player_uuid)

      {:ok, game_with_track3} = Game.set_turn_track(game_step2, track3)
      game_step3 = Game.extend_user_timeline(game_with_track3, first_player_uuid)

      {:ok, game_with_extra} = Game.set_turn_track(game_step3, extra_track)
      game = Game.extend_user_timeline(game_with_extra, first_player_uuid)

      updated_game = Game.next_phase(game)

      assert length(updated_game.turn.timeline) == 4
      assert List.last(updated_game.turn.timeline).title == "Extra Song"
      assert Turn.get_active_player(updated_game.turn) == first_player_uuid
    end

    test "adds tracks after snapshot creation does not affect snapshot", %{game: game} do
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      first_player_uuid = Turn.get_active_player(game.turn)

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, first_player_uuid)

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game_step2 = Game.extend_user_timeline(game_with_track2, first_player_uuid)

      {:ok, game_with_track3} = Game.set_turn_track(game_step2, track3)
      game = Game.extend_user_timeline(game_with_track3, first_player_uuid)

      original_timeline = [track1, track2, track3]

      game = Game.next_phase(game)

      assert game.turn.timeline == original_timeline

      new_track = Track.new(title: "New Song", artist: "Artist", year: 2024)
      {:ok, game_with_new_track} = Game.set_turn_track(game, new_track)
      updated_game = Game.extend_user_timeline(game_with_new_track, first_player_uuid)

      assert updated_game.turn.timeline == original_timeline
      assert length(Game.get_user_timeline(updated_game, first_player_uuid)) == 4
    end

    test "new player gets snapshot created when their turn starts", %{game: game, user2: user2} do
      track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)

      second_player_uuid = user2.uuid

      {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      game_step1 = Game.extend_user_timeline(game_with_track1, second_player_uuid)

      {:ok, game_with_track2} = Game.set_turn_track(game_step1, track2)
      game = Game.extend_user_timeline(game_with_track2, second_player_uuid)

      game =
        game
        |> Game.next_phase()
        |> Game.next_phase()
        |> Game.next_phase()
        |> Game.next_phase()

      game = Game.next_phase(game)

      assert game.turn.phase == :waiting
      assert Turn.get_active_player(game.turn) == second_player_uuid
      assert game.turn.timeline == []

      updated_game = Game.next_phase(game)

      assert updated_game.turn.phase == :ready
      assert length(updated_game.turn.timeline) == 2
      assert Turn.get_active_player(updated_game.turn) == second_player_uuid
    end

    test "awards points to first valid assumption during phase transition", %{
      game: game,
      user1: user1,
      user2: user2,
      user3: user3
    } do
      active_track = Track.new(title: "Mid Song", artist: "Artist", year: 2000)

      timeline = [
        Track.new(title: "Earlier Song", artist: "Artist", year: 1995),
        active_track,
        Track.new(title: "Later Song", artist: "Artist", year: 2005),
        Track.new(title: "Even Later Song", artist: "Artist", year: 2010),
        active_track,
        Track.new(title: "Newest Song", artist: "Artist", year: 2015),
        active_track
      ]

      turn = %Turn{
        phase: :challenging,
        timeline: timeline,
        track: active_track,
        assumptions: [
          %{position: 1, user_id: user1.uuid},
          %{position: 4, user_id: user2.uuid},
          %{position: 6, user_id: user3.uuid}
        ]
      }

      game = %{game | turn: turn}

      assert Map.get(game.scores, user1.uuid, 0) == 0
      assert Map.get(game.scores, user2.uuid, 0) == 0
      assert Map.get(game.scores, user3.uuid, 0) == 0

      updated_game = Game.next_phase(game)

      assert updated_game.turn.phase == :results

      assert Map.get(updated_game.scores, user1.uuid, 0) == 1
      assert Map.get(updated_game.scores, user2.uuid, 0) == 0
      assert Map.get(updated_game.scores, user3.uuid, 0) == 0
    end

    test "adds track to winner's timeline during phase transition", %{
      game: game,
      user1: user1,
      user2: user2
    } do
      active_track = Track.new(title: "Mid Song", artist: "Artist", year: 2000)

      timeline = [
        Track.new(title: "Earlier Song", artist: "Artist", year: 1995),
        active_track,
        Track.new(title: "Later Song", artist: "Artist", year: 2005)
      ]

      turn = %Turn{
        phase: :challenging,
        timeline: timeline,
        track: active_track,
        assumptions: [
          %{position: 1, user_id: user1.uuid},
          %{position: 4, user_id: user2.uuid}
        ]
      }

      game = %{game | turn: turn}

      existing_track1 = Track.new(title: "Old Track", artist: "Artist", year: 1990)
      existing_track2 = Track.new(title: "New Track", artist: "Artist", year: 2010)

      game = Game.init_user_timeline(game, user1.uuid, existing_track1)
      game = Game.extend_user_timeline(game, user1.uuid)

      turn = %{turn | track: Track.new(title: "Test Track", artist: "Artist", year: 2005)}
      game = %{game | turn: turn}

      game = %{game | timelines: Map.put(game.timelines, user1.uuid, [existing_track1, existing_track2])}

      assert length(Game.get_user_timeline(game, user1.uuid)) == 2
      assert Game.get_user_timeline(game, user2.uuid) == []

      updated_game = Game.next_phase(game)

      user1_timeline = Game.get_user_timeline(updated_game, user1.uuid)
      assert length(user1_timeline) == 3

      assert Enum.at(user1_timeline, 0).year == 1990
      assert Enum.at(user1_timeline, 1).year == 2005
      assert Enum.at(user1_timeline, 1).title == "Test Track"
      assert Enum.at(user1_timeline, 2).year == 2010

      assert Game.get_user_timeline(updated_game, user2.uuid) == []
    end

    test "awards no points when all assumptions are invalid", %{game: game, user1: user1, user2: user2} do
      active_track = Track.new(title: "Mid Song", artist: "Artist", year: 2000)

      timeline = [
        Track.new(title: "New Song", artist: "Artist", year: 2030),
        active_track,
        Track.new(title: "Old Song", artist: "Artist", year: 1970)
      ]

      turn = %Turn{
        phase: :challenging,
        timeline: timeline,
        track: active_track,
        assumptions: [
          %{position: 1, user_id: user1.uuid},
          %{position: 1, user_id: user2.uuid}
        ]
      }

      game = %{game | turn: turn}

      updated_game = Game.next_phase(game)

      assert Map.get(updated_game.scores, user1.uuid, 0) == 0
      assert Map.get(updated_game.scores, user2.uuid, 0) == 0
    end

    test "awards points to first valid assumption when multiple assumptions are valid", %{
      game: game,
      user1: user1,
      user2: user2,
      user3: user3
    } do
      active_track = Track.new(title: "Mid", artist: "Artist", year: 2000)

      timeline = [
        Track.new(title: "Old", artist: "Artist", year: 1980),
        active_track,
        active_track,
        active_track,
        Track.new(title: "New", artist: "Artist", year: 2020)
      ]

      turn = %Turn{
        phase: :challenging,
        timeline: timeline,
        track: active_track,
        assumptions: [
          %{position: 1, user_id: user3.uuid},
          %{position: 2, user_id: user1.uuid},
          %{position: 3, user_id: user2.uuid}
        ]
      }

      game = %{game | turn: turn}

      updated_game = Game.next_phase(game)

      assert Map.get(updated_game.scores, user3.uuid, 0) == 1
      assert Map.get(updated_game.scores, user1.uuid, 0) == 0
      assert Map.get(updated_game.scores, user2.uuid, 0) == 0
    end

    test "handles edge cases with empty timeline and boundary positions", %{game: game, user1: user1, user2: user2} do
      active_track = Track.new(title: "Current", artist: "Artist", year: 1995)

      timeline = [active_track]

      turn = %Turn{
        phase: :challenging,
        timeline: timeline,
        track: active_track,
        assumptions: [
          %{position: 0, user_id: user1.uuid},
          %{position: 1, user_id: user2.uuid}
        ]
      }

      game = %{game | turn: turn}

      updated_game = Game.next_phase(game)

      assert Map.get(updated_game.scores, user1.uuid, 0) == 1
      assert Map.get(updated_game.scores, user2.uuid, 0) == 0
    end

    test "handles assumptions beyond timeline length", %{game: game, user1: user1, user2: user2} do
      active_track = Track.new(title: "Current", artist: "Artist", year: 1995)

      timeline = [
        active_track,
        Track.new(title: "Second", artist: "Artist", year: 2000)
      ]

      turn = %Turn{
        phase: :challenging,
        timeline: timeline,
        track: active_track,
        assumptions: [
          %{position: 0, user_id: user1.uuid},
          %{position: 1, user_id: user2.uuid},
          %{position: 2, user_id: user1.uuid}
        ]
      }

      game = %{game | turn: turn}

      updated_game = Game.next_phase(game)

      assert Map.get(updated_game.scores, user1.uuid, 0) == 1
      assert Map.get(updated_game.scores, user2.uuid, 0) == 0
    end

    test "does not award points for non-challenging phase transitions", %{game: game, user1: user1} do
      turn = %Turn{
        phase: :ready,
        timeline: [],
        track: Track.new(title: "Song", artist: "Artist", year: 2000),
        assumptions: [
          %{position: 0, user_id: user1.uuid}
        ]
      }

      game = %{game | turn: turn}

      updated_game = Game.next_phase(game)

      assert updated_game.turn.phase == :steady
      assert Map.get(updated_game.scores, user1.uuid, 0) == 0
    end
  end

  describe "get_active_player/1" do
    test "returns current player from game turn" do
      owner_uuid = "owner123"

      game = Game.new(owner_uuid)

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

      game = Game.new(owner_uuid)

      assert Game.get_active_player(game) == nil
    end
  end
end
