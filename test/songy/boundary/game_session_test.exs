defmodule Songy.Boundary.GameSessionTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.GameSession
  alias Songy.Core.{Provider, Game}

  describe "create_game_session/2" do
    test "starts new game session process with owner and provider" do
      owner_uuid = "owner123"
      provider_id = :spotify
      assert {:ok, game} = GameSession.create_game_session(owner_uuid, provider_id)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      assert Process.alive?(pid)
      assert game.uuid != nil
      assert game.participants == []
      assert game.owner_uuid == owner_uuid
      assert %Provider{id: :spotify} = game.provider
    end

    test "multiple different games can be started with different owners and providers" do
      assert {:ok, game1} = GameSession.create_game_session("owner1", :spotify)
      assert {:ok, game2} = GameSession.create_game_session("owner2", :spotify)

      assert [{pid1, _}] = Registry.lookup(Songy.Registry, game1.uuid)
      assert [{pid2, _}] = Registry.lookup(Songy.Registry, game2.uuid)

      assert Process.alive?(pid1)
      assert Process.alive?(pid2)
      assert pid1 != pid2
      assert game1.uuid != game2.uuid
      assert game1.owner_uuid == "owner1"
      assert game2.owner_uuid == "owner2"
      assert %Provider{id: :spotify} = game1.provider
      assert %Provider{id: :spotify} = game2.provider
    end
  end

  describe "end_game_session/1" do
    test "terminates game session process" do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      assert :ok = GameSession.end_game_session(game.uuid)
    end

    test "handles termination of non-existent session" do
      assert :ok = GameSession.end_game_session("nonexistent")
    end
  end

  describe "remove_participant/2" do
    setup do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      %{game: game, pid: pid}
    end

    test "removes participant from game session", %{game: game, pid: pid} do
      participant_uuid = "user123"

      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      # Simulate participant joining via Presence (direct GenServer message)
      send(pid, {:participant_joined, participant_uuid})

      assert_receive {:game_state_updated, game_with_participant}

      # Verify participant was added
      assert length(game_with_participant.participants) == 1

      # Remove participant via API
      assert {:ok, updated_game} = GameSession.remove_participant(game.uuid, participant_uuid)
      assert length(updated_game.participants) == 0
    end

    test "returns error when removing non-existent participant", %{game: game} do
      assert {:error, :user_not_found} = GameSession.remove_participant(game.uuid, "nonexistent")
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.remove_participant("nonexistent", "user123")
    end
  end

  describe "lookup_game_session/1" do
    setup do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      %{game: game, pid: pid}
    end

    test "returns current game state", %{game: game} do
      assert {:ok, returned_game} = GameSession.lookup_game_session(game.uuid)
      assert returned_game.uuid == game.uuid
      assert returned_game.participants == []
      assert returned_game.status == :waiting
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.lookup_game_session("nonexistent")
    end
  end

  describe "start_game_session/1" do
    setup do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      %{game: game, pid: pid}
    end

    test "starts the game by changing status to in_progress", %{game: game} do
      # Setup credentials and mock for successful track search
      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      :ok = GameSession.set_credentials(game.uuid, credentials)

      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Random Song",
           uri: "spotify:track:track123",
           artists: [%{"name" => "Random Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/cover.jpg"}]
           }
         }}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      # Verify initial status is :waiting
      assert {:ok, initial_game} = GameSession.lookup_game_session(game.uuid)
      assert initial_game.status == :waiting

      # Start the game
      assert {:ok, updated_game} = GameSession.start_game_session(game.uuid)
      assert updated_game.status == :in_progress
      assert updated_game.turn.track != nil
      assert updated_game.turn.track.title == "Random Song"

      # Verify the game state was persisted
      assert {:ok, persisted_game} = GameSession.lookup_game_session(game.uuid)
      assert persisted_game.status == :in_progress
      assert persisted_game.turn.track != nil
    end

    test "returns error when game is already started", %{game: game} do
      # Setup credentials and mock for successful track search
      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      :ok = GameSession.set_credentials(game.uuid, credentials)

      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Random Song",
           uri: "spotify:track:track123",
           artists: [%{"name" => "Random Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/cover.jpg"}]
           }
         }}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      # Start the game first
      assert {:ok, _} = GameSession.start_game_session(game.uuid)

      # Try to start again
      assert {:error, :game_already_started} = GameSession.start_game_session(game.uuid)
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.start_game_session("nonexistent")
    end
  end

  describe "owner?/2" do
    setup do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)
      %{game: game}
    end

    test "returns true when user is owner", %{game: game} do
      assert GameSession.owner?(game.uuid, "owner123") == true
    end

    test "returns false when user is not owner", %{game: game} do
      assert GameSession.owner?(game.uuid, "other456") == false
    end

    test "returns false for non-existent session" do
      assert GameSession.owner?("nonexistent", "user123") == false
    end
  end

  describe "update_provider/2" do
    setup do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)
      %{game: game}
    end

    test "updates provider successfully", %{game: game} do
      provider_data = %{device_id: "test-device-123"}

      assert {:ok, updated_game} = GameSession.update_provider(game.uuid, provider_data)
      assert updated_game.provider.meta.device_id == "test-device-123"
    end

    test "returns error for non-existent session" do
      provider_data = %{device_id: "test-device-123"}

      assert {:error, :game_session_not_found} = GameSession.update_provider("nonexistent", provider_data)
    end
  end

  describe "start_playback/3" do
    test "starts playback when game in progress" do
      # Create and start game session
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      # Setup credentials and mock for successful track search
      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      :ok = GameSession.set_credentials(game.uuid, credentials)

      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Random Song",
           uri: "spotify:track:track123",
           artists: [%{"name" => "Random Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/cover.jpg"}]
           }
         }}
      end)

      Repatch.patch(Songy.Boundary.Spotify, :start_playback, [mode: :shared], fn _credentials, _params ->
        {:ok, :playback_started}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      Repatch.allow(self(), pid)

      {:ok, _} = GameSession.start_game_session(game.uuid)

      # Verify initial playback state
      {:ok, initial_game} = GameSession.lookup_game_session(game.uuid)
      assert initial_game.player.is_playback == false

      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      :ok = GameSession.set_credentials(game.uuid, credentials)

      assert {:ok, updated_game} = GameSession.start_playback(game.uuid, :spotify)
      assert updated_game.player.is_playback == true

      # Verify state persisted
      {:ok, persisted_game} = GameSession.lookup_game_session(game.uuid)
      assert persisted_game.player.is_playback == true

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end

    test "returns error when game is in waiting status" do
      provider_id = :spotify
      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      # Don't start the game, leave it in :waiting status
      :ok = GameSession.set_credentials(game.uuid, credentials)
      assert {:error, :game_not_in_progress} = GameSession.start_playback(game.uuid, :spotify)

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.start_playback("nonexistent-uuid", :spotify)
    end

    test "idempotent when playback already started" do
      Repatch.patch(Songy.Boundary.Spotify, :start_playback, [mode: :shared], fn _credentials, _params ->
        {:ok, :playback_started}
      end)

      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)
      :ok = GameSession.set_credentials(game.uuid, credentials)

      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Random Song",
           uri: "spotify:track:track123",
           artists: [%{"name" => "Random Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/cover.jpg"}]
           }
         }}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      {:ok, _} = GameSession.start_game_session(game.uuid)

      # Start playback twice
      :ok = GameSession.set_credentials(game.uuid, credentials)
      assert {:ok, first_result} = GameSession.start_playback(game.uuid, :spotify)
      assert {:ok, second_result} = GameSession.start_playback(game.uuid, :spotify)

      # Both should show playback as true
      assert first_result.player.is_playback == true
      assert second_result.player.is_playback == true

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end
  end

  describe "pause_playback/3" do
    test "pauses playback when game is in progress" do
      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Test Track",
           uri: "spotify:track:track123",
           artists: [%{name: "Test Artist"}],
           duration_ms: 180_000,
           preview_url: "http://example.com/preview.mp3"
         }}
      end)

      Repatch.patch(Songy.Boundary.Spotify, :start_playback, [mode: :shared], fn _credentials, _params ->
        {:ok, :playback_started}
      end)

      Repatch.patch(Songy.Boundary.Spotify, :pause_playback, [mode: :shared], fn _credentials, _params ->
        {:ok, :playback_paused}
      end)

      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}

      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      Repatch.allow(self(), pid)

      :ok = GameSession.set_credentials(game.uuid, credentials)

      {:ok, _} = GameSession.start_game_session(game.uuid)

      {:ok, _} = GameSession.start_playback(game.uuid, :spotify)

      # Verify playback is started
      {:ok, playing_game} = GameSession.lookup_game_session(game.uuid)
      assert playing_game.player.is_playback == true

      # Pause playback
      assert {:ok, updated_game} = GameSession.pause_playback(game.uuid, :spotify)
      assert updated_game.player.is_playback == false

      # Verify state persisted
      {:ok, persisted_game} = GameSession.lookup_game_session(game.uuid)
      assert persisted_game.player.is_playback == false

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end

    test "returns error when game is in waiting status" do
      Repatch.patch(Songy.Boundary.Spotify, :pause_playback, [mode: :shared], fn _credentials, _params ->
        {:ok, :playback_paused}
      end)

      provider_id = :spotify
      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      # Don't start the game, leave it in :waiting status
      :ok = GameSession.set_credentials(game.uuid, credentials)
      assert {:error, :game_not_in_progress} = GameSession.pause_playback(game.uuid, :spotify)

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.pause_playback("nonexistent-uuid", :spotify)
    end

    test "idempotent when playback already paused" do
      Repatch.patch(Songy.Boundary.Spotify, :pause_playback, [mode: :shared], fn _credentials, _params ->
        {:ok, :playback_paused}
      end)

      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Test Track",
           uri: "spotify:track:track123",
           artists: [%{name: "Test Artist"}],
           duration_ms: 180_000,
           preview_url: "http://example.com/preview.mp3"
         }}
      end)

      {:ok, game} = GameSession.create_game_session("owner123", :spotify)
      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      :ok = GameSession.set_credentials(game.uuid, credentials)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      Repatch.allow(self(), pid)

      {:ok, _} = GameSession.start_game_session(game.uuid)

      # Verify playback is initially stopped
      {:ok, initial_game} = GameSession.lookup_game_session(game.uuid)
      assert initial_game.player.is_playback == false

      # Pause playback (should be idempotent)
      assert {:ok, first_result} = GameSession.pause_playback(game.uuid, :spotify)
      assert {:ok, second_result} = GameSession.pause_playback(game.uuid, :spotify)

      # Both should show playback as false
      assert first_result.player.is_playback == false
      assert second_result.player.is_playback == false

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end
  end

  describe "next_phase/1" do
    test "returns error for non-existent game session" do
      assert {:error, :game_session_not_found} = GameSession.next_phase("nonexistent")
    end

    test "returns error for game not in progress" do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      # Game is still in waiting status, not started
      assert {:error, :game_not_in_progress} = GameSession.next_phase(game.uuid)

      GameSession.end_game_session(game.uuid)
    end

    test "cycles through all phases correctly" do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}

      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Random Song",
           artists: [%{"name" => "Random Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/cover.jpg"}]
           }
         }}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      :ok = GameSession.set_credentials(game.uuid, credentials)
      {:ok, started_game} = GameSession.start_game_session(game.uuid)

      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      send(pid, {:participant_joined, "user1"})
      assert_receive {:game_state_updated, _updated_game_1}

      send(pid, {:participant_joined, "user2"})
      assert_receive {:game_state_updated, _updated_game_2}

      # Cycle through phases: waiting -> ready -> steady -> challenging -> results -> waiting
      assert started_game.turn.phase == :waiting

      {:ok, ready_game} = GameSession.next_phase(game.uuid)
      assert ready_game.turn.phase == :ready

      {:ok, steady_game} = GameSession.next_phase(game.uuid)
      assert steady_game.turn.phase == :steady

      {:ok, challenging_game} = GameSession.next_phase(game.uuid)
      assert challenging_game.turn.phase == :challenging

      {:ok, results_game} = GameSession.next_phase(game.uuid)
      assert results_game.turn.phase == :results

      {:ok, next_waiting_game} = GameSession.next_phase(game.uuid)
      assert next_waiting_game.turn.phase == :waiting

      GameSession.end_game_session(game.uuid)
    end

    test "fetches new track only when transitioning from results phase" do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}

      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Random Song",
           artists: [%{"name" => "Random Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/cover.jpg"}]
           }
         }}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      :ok = GameSession.set_credentials(game.uuid, credentials)
      {:ok, started_game} = GameSession.start_game_session(game.uuid)

      # Subscribe to game events to wait for participant initialization
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      # Add participants for proper turn management
      send(pid, {:participant_joined, "user1"})
      assert_receive {:game_state_updated, _updated_game_1}

      send(pid, {:participant_joined, "user2"})
      assert_receive {:game_state_updated, _updated_game_2}

      initial_track_id = started_game.turn.track.id

      # Cycle through phases: waiting -> ready -> steady -> challenging -> results
      # These transitions should NOT trigger track fetching
      {:ok, ready_game} = GameSession.next_phase(game.uuid)
      assert ready_game.turn.phase == :ready
      assert ready_game.turn.track.id == initial_track_id

      {:ok, steady_game} = GameSession.next_phase(game.uuid)
      assert steady_game.turn.phase == :steady
      assert steady_game.turn.track.id == initial_track_id

      {:ok, challenging_game} = GameSession.next_phase(game.uuid)
      assert challenging_game.turn.phase == :challenging
      assert challenging_game.turn.track.id == initial_track_id

      {:ok, results_game} = GameSession.next_phase(game.uuid)
      assert results_game.turn.phase == :results
      assert results_game.turn.track.id == initial_track_id

      # Transition from results -> waiting should fetch new track
      {:ok, next_waiting_game} = GameSession.next_phase(game.uuid)
      assert next_waiting_game.turn.phase == :waiting

      # Verify that a new track was set with different ID
      assert next_waiting_game.turn.track != nil
      assert next_waiting_game.turn.track.id != initial_track_id

      GameSession.end_game_session(game.uuid)
    end
  end

  describe ":participant_joined event" do
    test "broadcasts event state update" do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      send(pid, {:participant_joined, "user456"})

      assert_receive {:game_state_updated, updated_game}

      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == "user456"

      GameSession.end_game_session(game.uuid)
    end

    test "updates game state with new participant" do
      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _provider ->
        {:ok,
         %Spotify.Track{
           name: "Test Track",
           uri: "spotify:track:track123",
           artists: [%{name: "Test Artist"}],
           duration_ms: 180_000,
           preview_url: "http://example.com/preview.mp3"
         }}
      end)

      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      :ok = GameSession.set_credentials(game.uuid, credentials)

      Repatch.allow(self(), pid)

      assert {:ok, game} = GameSession.start_game_session(game.uuid)
      assert length(game.participants) == 0

      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      send(pid, {:participant_joined, "owner123"})

      assert_receive {:game_state_updated, _updated_game}

      assert {:ok, updated_game} = GameSession.lookup_game_session(game.uuid)

      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == "owner123"
    end

    test "adds initial track to user timeline" do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)
      %{meta: credentials} = Provider.new(:spotify, %{access_token: "test_token"})

      # Setup mock for successful random track search
      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Random Song",
           uri: "spotify:track:track123",
           artists: [%{"name" => "Random Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/cover.jpg"}]
           }
         }}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      # Set credentials first
      assert :ok = GameSession.set_credentials(game.uuid, credentials)

      # Verify credentials are set
      assert {:ok, stored_creds} = GameSession.get_credentials(game.uuid)
      assert stored_creds.access_token == "test_token"

      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

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
      assert Repatch.called?(Songy.Boundary.Spotify, :search_random_track, 1, by: pid)

      GameSession.end_game_session(game.uuid)
    end

    test "handles missing credentials gracefully when adding random track" do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      # Send participant joined event without setting credentials
      send(pid, {:participant_joined, "user456"})

      # Verify participant was added but no random track (due to missing credentials)
      assert_receive {:game_state_updated, updated_game}
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == "user456"

      # Check that no track was added to user's timeline
      user_timeline = Game.get_user_timeline(updated_game, "user456")
      assert length(user_timeline) == 0

      GameSession.end_game_session(game.uuid)
    end

    test "handles random track search failure gracefully" do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)
      %{meta: credentials} = Provider.new(:spotify, %{access_token: "valid_token"})

      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:error, :no_tracks_found}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      # Set credentials first
      :ok = GameSession.set_credentials(game.uuid, credentials)

      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

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
      assert Repatch.called?(Songy.Boundary.Spotify, :search_random_track, 1, by: pid)

      GameSession.end_game_session(game.uuid)
    end

    test "handles Spotify API error gracefully" do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)
      %{meta: credentials} = Provider.new(:spotify, %{access_token: "invalid_token"})

      # Setup mock for Spotify API error
      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:error, :search_failed}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      # Set credentials first
      :ok = GameSession.set_credentials(game.uuid, credentials)

      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

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
      assert Repatch.called?(Songy.Boundary.Spotify, :search_random_track, 1, by: pid)

      GameSession.end_game_session(game.uuid)
    end

    test "does not add duplicate track when user with existing timeline rejoins" do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)
      %{meta: credentials} = Provider.new(:spotify, %{access_token: "test_token"})

      # Setup mock for random track search - should only be called once
      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Original Song",
           uri: "spotify:track:track123",
           artists: [%{"name" => "Original Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/cover.jpg"}]
           }
         }}
      end)

      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      # Set credentials first
      assert :ok = GameSession.set_credentials(game.uuid, credentials)

      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

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
      assert Repatch.called?(Songy.Boundary.Spotify, :search_random_track, 1, by: pid)

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
      assert Repatch.called?(Songy.Boundary.Spotify, :search_random_track, 1, by: pid)

      GameSession.end_game_session(game.uuid)
    end
  end

  describe "set_credentials/2" do
    test "stores provider credentials successfully" do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      provider = Provider.new(:spotify, %{access_token: "test_token", device_id: "test_device"})

      assert :ok = GameSession.set_credentials(game.uuid, provider)
      assert {:ok, credentials} = GameSession.get_credentials(game.uuid)
      assert credentials.access_token == "test_token"

      GameSession.end_game_session(game.uuid)
    end

    test "returns error for non-existent session" do
      provider = Provider.new(:spotify, %{access_token: "test_token"})

      assert {:error, :game_session_not_found} = GameSession.set_credentials("nonexistent", provider)
    end
  end

  describe "get_credentials/1" do
    test "retrieves stored credentials successfully" do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      provider = Provider.new(:spotify, %{access_token: "test_token", device_id: "test_device"})
      assert :ok = GameSession.set_credentials(game.uuid, provider)

      # Get credentials
      assert {:ok, credentials} = GameSession.get_credentials(game.uuid)
      assert credentials.access_token == "test_token"

      GameSession.end_game_session(game.uuid)
    end

    test "returns error when no credentials stored" do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      # Try to get credentials when none are stored
      assert {:error, :no_credentials} = GameSession.get_credentials(game.uuid)

      GameSession.end_game_session(game.uuid)
    end

    test "returns error for non-existent session" do
      assert {:error, :game_session_not_found} = GameSession.get_credentials("nonexistent")
    end

    test "credentials are cleaned up when session terminates" do
      provider_id = :spotify
      {:ok, game} = GameSession.create_game_session("owner123", provider_id)

      provider = Provider.new(:spotify, %{access_token: "test_token"})
      assert :ok = GameSession.set_credentials(game.uuid, provider)
      assert [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      # Verify credentials are stored
      assert [{_pid, _credentials}] = Registry.lookup(Songy.Registry, {:credentials, game.uuid})

      monitor_ref = Process.monitor(pid)

      # Terminate session
      GameSession.end_game_session(game.uuid)

      assert_receive {:DOWN, ^monitor_ref, :process, ^pid, _reason}

      # Verify credentials are cleaned up
      assert [] == Registry.lookup(Songy.Registry, {:credentials, game.uuid})
    end
  end

  describe "make_assumption/3" do
    setup do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      :ok = GameSession.set_credentials(game.uuid, credentials)

      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Turn Track",
           uri: "spotify:track:track123",
           artists: [%{"name" => "Turn Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/cover.jpg"}]
           }
         }}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      # Start game to set turn track
      {:ok, started_game} = GameSession.start_game_session(game.uuid)

      %{game: started_game, pid: pid}
    end

    test "adds current turn track to active timeline at specified position", %{game: game, pid: pid} do
      user_uuid = "user123"

      # Subscribe to state updates before adding participant
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      # Add participant and wait for initialization to complete
      send(pid, {:participant_joined, user_uuid})

      assert_receive {:game_state_updated, _game_with_participant}

      # First, transition to ready phase to create active timeline snapshot
      {:ok, ready_game} = GameSession.next_phase(game.uuid)
      assert ready_game.turn.phase == :ready
      # Should have snapshot of user's timeline (1 initial track)
      assert length(ready_game.turn.timeline) == 1

      # Make assumption by adding turn track at position 1
      assert {:ok, updated_game} = GameSession.make_assumption(game.uuid, user_uuid, 1)

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
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      # Add participant and wait for initialization to complete
      send(pid, {:participant_joined, user_uuid})
      assert_receive {:game_state_updated, _game_with_participant}

      # First, transition to ready phase to create active timeline snapshot
      {:ok, ready_game} = GameSession.next_phase(game.uuid)
      assert ready_game.turn.phase == :ready

      # Add turn track at position 0
      assert {:ok, updated_game} = GameSession.make_assumption(game.uuid, user_uuid, 0)

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
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      # Add participant and wait for initialization to complete
      send(pid, {:participant_joined, user_uuid})
      assert_receive {:game_state_updated, _game_with_participant}

      # First, transition to ready phase to create active timeline snapshot
      {:ok, ready_game} = GameSession.next_phase(game.uuid)
      assert ready_game.turn.phase == :ready

      # Add turn track using default position (should be 0)
      assert {:ok, updated_game} = GameSession.make_assumption(game.uuid, user_uuid)

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
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      # Setup credentials
      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}

      :ok = GameSession.set_credentials(game.uuid, credentials)

      Repatch.patch(Songy.Boundary.Spotify, :search_random_track, [mode: :shared], fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Test Track",
           uri: "spotify:track:test123",
           artists: [%{"name" => "Test Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/test.jpg"}]
           }
         }}
      end)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      Repatch.allow(self(), pid)

      # Add participant to get initial timeline
      user_uuid = "user123"

      # Subscribe to state updates before adding participant
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      send(pid, {:participant_joined, user_uuid})

      assert_receive {:game_state_updated, game_with_user}

      %{game: game_with_user, pid: pid, user_uuid: user_uuid}
    end

    test "reorders existing track to new position in active timeline", %{game: game, user_uuid: user_uuid} do
      {:ok, _started_game} = GameSession.start_game_session(game.uuid)

      {:ok, game} = GameSession.make_assumption(game.uuid, user_uuid, 0)

      # TODO: Should implement full cycle phase and create a new turn track
      {:ok, game} = GameSession.next_phase(game.uuid)

      assert_receive {:game_state_updated, %{turn: %{timeline: [track]}}}

      assert {:ok, _} =
               GameSession.reorder_timeline(game.uuid, track.id, 1)

      assert_receive {:game_state_updated, %{turn: %{timeline: [^track]}}}
    end

    test "returns error for non-existent track ID", %{game: game} do
      assert {:error, :track_not_found} = GameSession.reorder_timeline(game.uuid, "nonexistent_track", 0)
    end

    test "returns error for non-existent game session" do
      assert {:error, :game_session_not_found} = GameSession.reorder_timeline("nonexistent", "track123", 0)
    end

    test "returns error when active timeline is empty", %{game: game} do
      # Game has turn but empty timeline, should return track not found
      assert {:error, :track_not_found} = GameSession.reorder_timeline(game.uuid, "any_track", 0)
    end

    test "broadcasts state update even when reordering fails", %{game: game} do
      # Subscribe to state updates
      Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game.uuid}")

      # Try to reorder non-existent track
      assert {:error, :track_not_found} = GameSession.reorder_timeline(game.uuid, "nonexistent", 0)

      # Should not receive any broadcast for failed operation
      refute_receive {:game_state_updated, _}, 100
    end
  end
end
