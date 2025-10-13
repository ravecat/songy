defmodule Songy.Boundary.GameSessionTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.GameSession
  alias Songy.Core.Game

  setup do
    Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn :providers, _user_uuid ->
      {:ok,
       %Songy.Core.Provider.Spotify{access_token: "test-token", refresh_token: "test-refresh", device_id: "test-device"}}
    end)

    :ok
  end

  describe "create_game_session/1" do
    test "starts new game session process with owner" do
      owner_uuid = "owner123"
      assert {:ok, game} = GameSession.create_game_session(owner_uuid)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      assert Process.alive?(pid)
      assert game.id != nil
      assert game.participants == []
      assert game.owner_uuid == owner_uuid
      # assert game.provider_id == :spotify
    end

    test "multiple different games can be started with different owners" do
      assert {:ok, game1} = GameSession.create_game_session("owner1")
      assert {:ok, game2} = GameSession.create_game_session("owner2")

      assert [{pid1, _}] = Registry.lookup(Songy.Registry, game1.id)
      assert [{pid2, _}] = Registry.lookup(Songy.Registry, game2.id)

      assert Process.alive?(pid1)
      assert Process.alive?(pid2)
      assert pid1 != pid2
      assert game1.id != game2.id
      assert game1.owner_uuid == "owner1"
      assert game2.owner_uuid == "owner2"
      # assert game1.provider_id == :spotify
      # assert game2.provider_id == :spotify
    end
  end

  describe "end_game_session/1" do
    test "terminates game session process" do
      {:ok, game} = GameSession.create_game_session("owner123")

      assert :ok = GameSession.end_game_session(game.id)
    end

    test "handles termination of non-existent session" do
      assert :ok = GameSession.end_game_session("nonexistent")
    end
  end

  describe "remove_participant/2" do
    setup do
      {:ok, game} = GameSession.create_game_session("owner123")

      on_exit(fn -> GameSession.end_game_session(game.id) end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      %{game: game, pid: pid}
    end

    test "removes participant from game session", %{game: game, pid: pid} do
      participant_uuid = "user123"

      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # Simulate participant joining via Presence (direct GenServer message)
      send(pid, {:participant_joined, participant_uuid})

      assert_receive {:game_state_updated, game_with_participant}

      # Verify participant was added
      assert length(game_with_participant.participants) == 1

      # Remove participant via API
      assert {:ok, updated_game} = GameSession.remove_participant(game.id, participant_uuid)
      assert length(updated_game.participants) == 0
    end

    test "returns error when removing non-existent participant", %{game: game} do
      assert {:error, :user_not_found} = GameSession.remove_participant(game.id, "nonexistent")
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.remove_participant("nonexistent", "user123")
    end
  end

  describe "lookup_game_session/1" do
    setup do
      {:ok, game} = GameSession.create_game_session("owner123")

      on_exit(fn -> GameSession.end_game_session(game.id) end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      %{game: game, pid: pid}
    end

    test "returns current game state", %{game: game} do
      assert {:ok, returned_game} = GameSession.lookup_game_session(game.id)
      assert returned_game.id == game.id
      assert returned_game.participants == []
      assert returned_game.status == :waiting
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.lookup_game_session("nonexistent")
    end
  end

  describe "start_game_session/1" do
    setup do
      {:ok, game} = GameSession.create_game_session("owner123")

      on_exit(fn -> GameSession.end_game_session(game.id) end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      %{game: game, pid: pid}
    end

    test "starts the game by changing status to in_progress", %{game: game} do
      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "track123",
           title: "Random Song",
           artist: "Random Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:track123"}
         }}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      # Verify initial status is :waiting
      assert {:ok, initial_game} = GameSession.lookup_game_session(game.id)
      assert initial_game.status == :waiting

      # Start the game
      assert {:ok, updated_game} = GameSession.start_game_session(game.id)
      assert updated_game.status == :in_progress
      assert updated_game.turn.track != nil
      assert updated_game.turn.track.title == "Random Song"

      # Verify the game state was persisted
      assert {:ok, persisted_game} = GameSession.lookup_game_session(game.id)
      assert persisted_game.status == :in_progress
      assert persisted_game.turn.track != nil
    end

    test "returns error when game is already started", %{game: game} do
      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "track123",
           title: "Random Song",
           artist: "Random Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:track123"}
         }}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      # Start the game first
      assert {:ok, _} = GameSession.start_game_session(game.id)

      # Try to start again
      assert {:error, :game_already_started} = GameSession.start_game_session(game.id)
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.start_game_session("nonexistent")
    end
  end

  describe "owner?/2" do
    setup do
      {:ok, game} = GameSession.create_game_session("owner123")

      on_exit(fn -> GameSession.end_game_session(game.id) end)

      %{game: game}
    end

    test "returns true when user is owner", %{game: game} do
      assert GameSession.owner?(game.id, "owner123") == true
    end

    test "returns false when user is not owner", %{game: game} do
      assert GameSession.owner?(game.id, "other456") == false
    end

    test "returns false for non-existent session" do
      assert GameSession.owner?("nonexistent", "user123") == false
    end
  end

  describe "start_playback/1" do
    setup do
      {:ok, game} = GameSession.create_game_session("owner123")

      on_exit(fn -> GameSession.end_game_session(game.id) end)

      %{game: game}
    end

    test "starts playback when game in progress", %{game: game} do
      # Setup credentials and mock for successful track search

      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "track123",
           title: "Random Song",
           artist: "Random Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:track123"}
         }}
      end)

      Repatch.patch(Songy.Boundary.Player, :start_playback, [mode: :shared], fn _provider, _opts ->
        {:ok, :playback_started}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      Repatch.allow(self(), pid)

      {:ok, _} = GameSession.start_game_session(game.id)

      # Verify initial playback state
      {:ok, initial_game} = GameSession.lookup_game_session(game.id)
      assert initial_game.player.is_playback == false

      assert {:ok, updated_game} = GameSession.start_playback(game.id)
      assert updated_game.player.is_playback == true

      # Verify state persisted
      {:ok, persisted_game} = GameSession.lookup_game_session(game.id)
      assert persisted_game.player.is_playback == true
    end

    test "returns error when game is in waiting status", %{game: game} do
      # Don't start the game, leave it in :waiting status
      assert {:error, :game_not_in_progress} = GameSession.start_playback(game.id)
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.start_playback("nonexistent-uuid")
    end

    test "idempotent when playback already started", %{game: game} do
      Repatch.patch(Songy.Boundary.Player, :start_playback, [mode: :shared], fn _provider, _opts ->
        {:ok, :playback_started}
      end)

      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "track123",
           title: "Random Song",
           artist: "Random Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:track123"}
         }}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      {:ok, _} = GameSession.start_game_session(game.id)

      # Start playback twice
      assert {:ok, first_result} = GameSession.start_playback(game.id)
      assert {:ok, second_result} = GameSession.start_playback(game.id)

      # Both should show playback as true
      assert first_result.player.is_playback == true
      assert second_result.player.is_playback == true
    end
  end

  describe "pause_playback/1" do
    setup do
      {:ok, game} = GameSession.create_game_session("owner123")

      on_exit(fn -> GameSession.end_game_session(game.id) end)

      %{game: game}
    end

    test "pauses playback when game is in progress", %{game: game} do
      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "track123",
           title: "Test Track",
           artist: "Test Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:track123"}
         }}
      end)

      Repatch.patch(Songy.Boundary.Player, :start_playback, [mode: :shared], fn _provider, _opts ->
        {:ok, :playback_started}
      end)

      Repatch.patch(Songy.Boundary.Player, :pause_playback, [mode: :shared], fn _provider, _opts ->
        {:ok, :playback_paused}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      Repatch.allow(self(), pid)

      {:ok, _} = GameSession.start_game_session(game.id)

      {:ok, _} = GameSession.start_playback(game.id)

      # Verify playback is started
      {:ok, playing_game} = GameSession.lookup_game_session(game.id)
      assert playing_game.player.is_playback == true

      # Pause playback
      assert {:ok, updated_game} = GameSession.pause_playback(game.id)
      assert updated_game.player.is_playback == false

      # Verify state persisted
      {:ok, persisted_game} = GameSession.lookup_game_session(game.id)
      assert persisted_game.player.is_playback == false
    end

    test "returns error when game is in waiting status", %{game: game} do
      Repatch.patch(Songy.Boundary.Player, :pause_playback, [mode: :shared], fn _provider, _opts ->
        {:ok, :playback_paused}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      # Don't start the game, leave it in :waiting status
      assert {:error, :game_not_in_progress} = GameSession.pause_playback(game.id)
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.pause_playback("nonexistent-uuid")
    end

    test "idempotent when playback already paused", %{game: game} do
      Repatch.patch(Songy.Boundary.Player, :pause_playback, [mode: :shared], fn _provider, _opts ->
        {:ok, :playback_paused}
      end)

      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "track123",
           title: "Test Track",
           artist: "Test Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:track123"}
         }}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      Repatch.allow(self(), pid)

      {:ok, _} = GameSession.start_game_session(game.id)

      # Verify playback is initially stopped
      {:ok, initial_game} = GameSession.lookup_game_session(game.id)
      assert initial_game.player.is_playback == false

      # Pause playback (should be idempotent)
      assert {:ok, first_result} = GameSession.pause_playback(game.id)
      assert {:ok, second_result} = GameSession.pause_playback(game.id)

      # Both should show playback as false
      assert first_result.player.is_playback == false
      assert second_result.player.is_playback == false
    end
  end

  describe "next_phase/1" do
    setup do
      {:ok, game} = GameSession.create_game_session("owner123")

      on_exit(fn -> GameSession.end_game_session(game.id) end)

      %{game: game}
    end

    test "returns error for non-existent game session" do
      assert {:error, :game_session_not_found} = GameSession.next_phase("nonexistent")
    end

    test "returns error for game not in progress", %{game: game} do
      assert {:error, :game_not_in_progress} = GameSession.next_phase(game.id)
    end

    test "cycles through all phases correctly", %{game: game} do
      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "test123",
           title: "Random Song",
           artist: "Random Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:test123"}
         }}
      end)

      Repatch.patch(Songy.Boundary.Player, :pause_playback, [mode: :shared], fn _provider ->
        {:ok, :playback_paused}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      {:ok, started_game} = GameSession.start_game_session(game.id)

      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      send(pid, {:participant_joined, "user1"})
      assert_receive {:game_state_updated, _updated_game_1}

      send(pid, {:participant_joined, "user2"})
      assert_receive {:game_state_updated, _updated_game_2}

      # Cycle through phases: waiting -> ready -> steady -> challenging -> results -> waiting
      assert started_game.turn.phase == :waiting

      {:ok, ready_game} = GameSession.next_phase(game.id)
      assert ready_game.turn.phase == :ready

      {:ok, steady_game} = GameSession.next_phase(game.id)
      assert steady_game.turn.phase == :steady

      {:ok, challenging_game} = GameSession.next_phase(game.id)
      assert challenging_game.turn.phase == :challenging

      {:ok, results_game} = GameSession.next_phase(game.id)
      assert results_game.turn.phase == :results

      {:ok, next_waiting_game} = GameSession.next_phase(game.id)
      assert next_waiting_game.turn.phase == :waiting
    end

    test "fetches new track only when transitioning from results phase", %{game: game} do
      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        track_id = "track_#{:erlang.unique_integer([:positive])}"

        {:ok,
         %Songy.Core.Track{
           id: track_id,
           title: "Random Song",
           artist: "Random Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:#{track_id}"}
         }}
      end)

      Repatch.patch(Songy.Boundary.Player, :pause_playback, [mode: :shared], fn _provider ->
        {:ok, :playback_paused}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      {:ok, started_game} = GameSession.start_game_session(game.id)

      # Subscribe to game events to wait for participant initialization
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # Add participants for proper turn management
      send(pid, {:participant_joined, "user1"})
      assert_receive {:game_state_updated, _updated_game_1}

      send(pid, {:participant_joined, "user2"})
      assert_receive {:game_state_updated, _updated_game_2}

      initial_track_id = started_game.turn.track.id

      # Cycle through phases: waiting -> ready -> steady -> challenging -> results
      {:ok, ready_game} = GameSession.next_phase(game.id)
      assert ready_game.turn.phase == :ready
      assert ready_game.turn.track.id == initial_track_id

      {:ok, steady_game} = GameSession.next_phase(game.id)
      assert steady_game.turn.phase == :steady
      assert steady_game.turn.track.id == initial_track_id

      {:ok, challenging_game} = GameSession.next_phase(game.id)
      assert challenging_game.turn.phase == :challenging
      assert challenging_game.turn.track.id == initial_track_id

      {:ok, results_game} = GameSession.next_phase(game.id)
      assert results_game.turn.phase == :results
      assert results_game.turn.track.id == initial_track_id

      # Transition from results -> waiting should fetch new track
      {:ok, next_waiting_game} = GameSession.next_phase(game.id)
      assert next_waiting_game.turn.phase == :waiting

      # Verify that a new track was set with different ID
      assert next_waiting_game.turn.track != nil
      assert next_waiting_game.turn.track.id != initial_track_id
    end

    test "automatically transitions from challenging to results after timeout", %{game: game} do
      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "test123",
           title: "Random Song",
           artist: "Random Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:test123"}
         }}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      Repatch.allow(self(), pid)

      {:ok, _started_game} = GameSession.start_game_session(game.id)

      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      send(pid, {:participant_joined, "user1"})
      assert_receive {:game_state_updated, _updated_game_1}

      send(pid, {:participant_joined, "user2"})
      assert_receive {:game_state_updated, _updated_game_2}

      # Move to challenging phase: waiting -> ready -> steady -> challenging
      {:ok, _ready_game} = GameSession.next_phase(game.id)
      {:ok, _steady_game} = GameSession.next_phase(game.id)
      {:ok, challenging_game} = GameSession.next_phase(game.id)

      assert challenging_game.turn.phase == :challenging

      assert_receive {:game_state_updated, %{turn: %{phase: :results}}}
    end
  end

  describe ":participant_joined event" do
    test "broadcasts event state update" do
      {:ok, game} = GameSession.create_game_session("owner123")

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      send(pid, {:participant_joined, "user456"})

      assert_receive {:game_state_updated, updated_game}

      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == "user456"

      GameSession.end_game_session(game.id)
    end

    test "updates game state with new participant" do
      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "track123",
           title: "Test Track",
           artist: "Test Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:track123"}
         }}
      end)

      {:ok, game} = GameSession.create_game_session("owner123")

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      Repatch.allow(self(), pid)

      assert {:ok, game} = GameSession.start_game_session(game.id)
      assert length(game.participants) == 0

      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      send(pid, {:participant_joined, "owner123"})

      assert_receive {:game_state_updated, _updated_game}

      assert {:ok, updated_game} = GameSession.lookup_game_session(game.id)

      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == "owner123"
    end

    test "adds initial track to user timeline" do
      {:ok, game} = GameSession.create_game_session("owner123")

      # Setup mock for successful random track search
      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "track123",
           title: "Random Song",
           artist: "Random Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:track123"}
         }}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      # Set credentials first

      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # Send participant joined event
      send(pid, {:participant_joined, "user456"})

      assert_receive {:game_state_updated, updated_game}

      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == "user456"

      user_timeline = Game.get_user_timeline(updated_game, "user456")
      assert length(user_timeline) == 1

      [track] = user_timeline
      assert track.title == "Random Song"
      assert track.artist == "Random Artist"
      assert track.year == 2023

      # Verify Spotify.search_random_track was called
      assert Repatch.called?(Songy.Boundary.Player, :search_random_track, 1, by: pid)

      GameSession.end_game_session(game.id)
    end

    test "handles missing credentials gracefully when adding random track" do
      {:ok, game} = GameSession.create_game_session("owner123")

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # Send participant joined event without setting credentials
      send(pid, {:participant_joined, "user456"})

      # Verify participant was added but no random track (due to missing credentials)
      assert_receive {:game_state_updated, updated_game}
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == "user456"

      # Check that no track was added to user's timeline
      user_timeline = Game.get_user_timeline(updated_game, "user456")
      assert length(user_timeline) == 0

      GameSession.end_game_session(game.id)
    end

    test "handles random track search failure gracefully" do
      {:ok, game} = GameSession.create_game_session("owner123")

      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:error, :no_tracks_found}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      # Set credentials first

      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # Send participant joined event
      send(pid, {:participant_joined, "user456"})

      # Verify participant was added but no random track (due to search failure)
      assert_receive {:game_state_updated, updated_game}
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == "user456"

      # Check that no track was added to user's timeline
      user_timeline = Game.get_user_timeline(updated_game, "user456")
      assert length(user_timeline) == 0

      # Verify Spotify.search_random_track was called but failed
      assert Repatch.called?(Songy.Boundary.Player, :search_random_track, 1, by: pid)

      GameSession.end_game_session(game.id)
    end

    test "handles Spotify API error gracefully" do
      {:ok, game} = GameSession.create_game_session("owner123")

      # Setup mock for Spotify API error
      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:error, :search_failed}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      # Set credentials first

      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # Send participant joined event
      send(pid, {:participant_joined, "user456"})

      # Verify participant was added but no random track (due to API error)
      assert_receive {:game_state_updated, updated_game}
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == "user456"

      # Check that no track was added to user's timeline
      user_timeline = Game.get_user_timeline(updated_game, "user456")
      assert length(user_timeline) == 0

      # Verify Spotify.search_random_track was called but failed
      assert Repatch.called?(Songy.Boundary.Player, :search_random_track, 1, by: pid)

      GameSession.end_game_session(game.id)
    end

    test "does not add duplicate track when user with existing timeline rejoins" do
      {:ok, game} = GameSession.create_game_session("owner123")

      # Setup mock for random track search - should only be called once
      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "track123",
           title: "Original Song",
           artist: "Original Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:track123"}
         }}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      # Set credentials first

      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # First join - should add initial track
      send(pid, {:participant_joined, "user456"})

      assert_receive {:game_state_updated, updated_game_first}
      assert length(updated_game_first.participants) == 1
      assert hd(updated_game_first.participants).uuid == "user456"

      # Verify initial track was added
      user_timeline_first = Game.get_user_timeline(updated_game_first, "user456")
      assert length(user_timeline_first) == 1
      [first_track] = user_timeline_first
      assert first_track.title == "Original Song"
      assert first_track.artist == "Original Artist"

      # Verify search_random_track was called once
      assert Repatch.called?(Songy.Boundary.Player, :search_random_track, 1, by: pid)

      # Simulate user leaving (they are removed from participants but timeline persists)
      send(pid, {:participant_left, "user456"})
      assert_receive {:game_state_updated, game_after_leave}
      assert length(game_after_leave.participants) == 0

      # Verify timeline still exists after leaving
      user_timeline_after_leave = Game.get_user_timeline(game_after_leave, "user456")
      assert length(user_timeline_after_leave) == 1

      # Second join (rejoin/page refresh) - should NOT add another track
      send(pid, {:participant_joined, "user456"})

      assert_receive {:game_state_updated, updated_game_second}
      assert length(updated_game_second.participants) == 1
      assert hd(updated_game_second.participants).uuid == "user456"

      # Verify timeline still has only 1 track (no duplicate added)
      user_timeline_second = Game.get_user_timeline(updated_game_second, "user456")
      assert length(user_timeline_second) == 1
      [second_track] = user_timeline_second
      assert second_track.title == "Original Song"
      assert second_track.artist == "Original Artist"

      # Verify search_random_track was still called only once (not called on rejoin)
      assert Repatch.called?(Songy.Boundary.Player, :search_random_track, 1, by: pid)

      GameSession.end_game_session(game.id)
    end
  end

  describe "make_assumption/3" do
    setup do
      {:ok, game} = GameSession.create_game_session("owner123")

      on_exit(fn -> GameSession.end_game_session(game.id) end)

      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "track123",
           title: "Turn Track",
           artist: "Turn Artist",
           year: 2023,
           cover_url: "https://example.com/cover.jpg",
           meta: %{uri: "spotify:track:track123"}
         }}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.id)
      Repatch.allow(self(), pid)

      # Start game to set turn track
      {:ok, started_game} = GameSession.start_game_session(game.id)

      %{game: started_game, pid: pid}
    end

    test "adds current turn track to active timeline at specified position", %{game: game, pid: pid} do
      user_uuid = "user123"

      # Subscribe to state updates before adding participant
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # Add participant and wait for initialization to complete
      send(pid, {:participant_joined, user_uuid})

      assert_receive {:game_state_updated, _game_with_participant}

      # First, transition to ready phase to create active timeline snapshot
      {:ok, ready_game} = GameSession.next_phase(game.id)
      assert ready_game.turn.phase == :ready
      # Should have snapshot of user's timeline (1 initial track)
      assert length(ready_game.turn.timeline) == 1

      # Make assumption by adding turn track at position 1
      assert {:ok, updated_game} = GameSession.make_assumption(game.id, user_uuid, 1)

      # Verify turn track was added to active timeline (turn.timeline)
      active_timeline = updated_game.turn.timeline
      # 1 initial + 1 from turn
      assert length(active_timeline) == 2
      # Should be in steady phase after assumption
      assert updated_game.turn.phase == :steady

      # Verify the turn track is at position 1
      [_initial_track, turn_track] = active_timeline
      assert turn_track.title == "Turn Track"
      assert turn_track.artist == "Turn Artist"
    end

    test "adds turn track at position 0 (beginning of active timeline)", %{game: game, pid: pid} do
      user_uuid = "user123"

      # Subscribe to state updates before adding participant
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # Add participant and wait for initialization to complete
      send(pid, {:participant_joined, user_uuid})
      assert_receive {:game_state_updated, _game_with_participant}

      # First, transition to ready phase to create active timeline snapshot
      {:ok, ready_game} = GameSession.next_phase(game.id)
      assert ready_game.turn.phase == :ready

      # Add turn track at position 0
      assert {:ok, updated_game} = GameSession.make_assumption(game.id, user_uuid, 0)

      active_timeline = updated_game.turn.timeline
      assert length(active_timeline) == 2
      assert updated_game.turn.phase == :steady

      # Verify turn track is at the beginning
      [turn_track, _initial_track] = active_timeline
      assert turn_track.title == "Turn Track"
    end

    test "uses default position 0 when position not specified", %{game: game, pid: pid} do
      user_uuid = "user123"

      # Subscribe to state updates before adding participant
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # Add participant and wait for initialization to complete
      send(pid, {:participant_joined, user_uuid})
      assert_receive {:game_state_updated, _game_with_participant}

      # First, transition to ready phase to create active timeline snapshot
      {:ok, ready_game} = GameSession.next_phase(game.id)
      assert ready_game.turn.phase == :ready

      # Add turn track using default position (should be 0)
      assert {:ok, updated_game} = GameSession.make_assumption(game.id, user_uuid)

      active_timeline = updated_game.turn.timeline
      assert length(active_timeline) == 2
      assert updated_game.turn.phase == :steady

      # Verify turn track is at the beginning (position 0)
      [turn_track, _initial_track] = active_timeline
      assert turn_track.title == "Turn Track"
    end

    test "returns error for non-existent game session" do
      assert {:error, :game_session_not_found} = GameSession.make_assumption("nonexistent", "user123", 0)
    end
  end

  describe "reorder_timeline/3" do
    setup do
      {:ok, game} = GameSession.create_game_session("owner123")

      on_exit(fn -> GameSession.end_game_session(game.id) end)

      # Setup credentials

      Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Songy.Core.Track{
           id: "test123",
           title: "Test Track",
           artist: "Test Artist",
           year: 2023,
           cover_url: "https://example.com/test.jpg",
           meta: %{uri: "spotify:track:test123"}
         }}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

      Repatch.allow(self(), pid)

      # Add participant to get initial timeline
      user_uuid = "user123"

      # Subscribe to state updates before adding participant
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      send(pid, {:participant_joined, user_uuid})

      assert_receive {:game_state_updated, game_with_user}

      %{game: game_with_user, pid: pid, user_uuid: user_uuid}
    end

    test "reorders existing track to new position in active timeline", %{game: game, user_uuid: user_uuid} do
      {:ok, _started_game} = GameSession.start_game_session(game.id)

      {:ok, game} = GameSession.make_assumption(game.id, user_uuid, 0)

      # TODO: Should implement full cycle phase and create a new turn track
      {:ok, game} = GameSession.next_phase(game.id)

      assert_receive {:game_state_updated, %{turn: %{timeline: [track]}}}

      assert {:ok, _} =
               GameSession.reorder_timeline(game.id, user_uuid, 1)

      assert_receive {:game_state_updated, %{turn: %{timeline: [^track]}}}
    end

    test "returns error for non-existent user", %{game: game} do
      assert {:error, :user_assumption_not_found} = GameSession.reorder_timeline(game.id, "nonexistent_user", 0)
    end

    test "returns error for non-existent game session" do
      assert {:error, :game_session_not_found} = GameSession.reorder_timeline("nonexistent", "user123", 0)
    end

    test "returns error when user has no assumption", %{game: game} do
      # Game has turn but user has no assumption, should return user not found
      assert {:error, :user_assumption_not_found} = GameSession.reorder_timeline(game.id, "any_user", 0)
    end

    test "broadcasts state update even when reordering fails", %{game: game} do
      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.id}")

      # Try to reorder for non-existent user
      assert {:error, :user_assumption_not_found} = GameSession.reorder_timeline(game.id, "nonexistent", 0)

      # Should not receive any broadcast for failed operation
      refute_receive {:game_state_updated, _}, 100
    end
  end
end
