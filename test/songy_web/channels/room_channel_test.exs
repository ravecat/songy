defmodule SongyWeb.RoomChannelTest do
  use SongyWeb.ChannelCase

  alias Songy.Boundary.GameSession
  alias Songy.Core.{Provider, User}

  defp join_room_channel(current_user, room_uuid, assigns \\ %{}) do
    default_assigns = %{current_user_uuid: current_user.uuid}

    SongyWeb.UserSocket
    |> socket("user_id", Map.merge(default_assigns, assigns))
    |> subscribe_and_join(SongyWeb.RoomChannel, "room:#{room_uuid}")
  end

  setup do
    current_user = User.get_user("test-uuid")

    %{current_user: current_user}
  end

  describe "channel join" do
    test "handles join succeeds", %{current_user: current_user} do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      {:ok, reply, _socket} = join_room_channel(current_user, game.uuid)
      assert reply == %{}

      GameSession.end_game_session(game.uuid)
    end

    test "stores credentials when owner joins with provider data", %{current_user: current_user} do
      provider = Provider.new(:spotify, %{access_token: "test_token", device_id: "test_device"})
      {:ok, game} = GameSession.create_game_session(current_user.uuid, :spotify)

      {:ok, _, _socket} = join_room_channel(current_user, game.uuid, %{provider: provider})

      # Verify credentials are stored
      assert {:ok, credentials} = GameSession.get_credentials(game.uuid)
      assert credentials.access_token == "test_token"

      GameSession.end_game_session(game.uuid)
    end

    test "does not store credentials when non-owner joins", %{current_user: current_user} do
      provider = Provider.new(:spotify, %{access_token: "test_token"})
      {:ok, game} = GameSession.create_game_session("other_owner", :spotify)

      # Join channel as non-owner with provider
      {:ok, _, _socket} = join_room_channel(current_user, game.uuid, %{provider: provider})

      # Verify no credentials are stored
      assert {:error, :no_credentials} = GameSession.get_credentials(game.uuid)

      GameSession.end_game_session(game.uuid)
    end

    test "does not store credentials when provider is nil", %{current_user: current_user} do
      {:ok, game} = GameSession.create_game_session(current_user.uuid, :spotify)

      # Join channel as owner without provider
      {:ok, _, _socket} = join_room_channel(current_user, game.uuid, %{provider: nil})

      # Verify no credentials are stored
      assert {:error, :no_credentials} = GameSession.get_credentials(game.uuid)

      GameSession.end_game_session(game.uuid)
    end
  end

  describe "start_game event" do
    test "changes game status and broadcasts update", %{current_user: current_user} do
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

      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      :ok = GameSession.set_credentials(game.uuid, credentials)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      Repatch.allow(self(), pid)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid)

      push(socket, "start_game", %{})

      assert_broadcast "state_updated", %{status: :in_progress}

      {:ok, updated_game} = GameSession.lookup_game_session(game.uuid)
      assert updated_game.status == :in_progress

      GameSession.end_game_session(game.uuid)
    end

    test "fails when game session does not exist", %{current_user: current_user} do
      {:ok, _, socket} = join_room_channel(current_user, "nonexistent")

      push(socket, "start_game", %{})

      refute_push "start_game", _
      refute_broadcast "state_updated", _
    end
  end

  describe "update_provider event" do
    test "refuses access to provider for non-owner user", %{current_user: current_user} do
      {:ok, game} = GameSession.create_game_session("other_owner", :spotify)

      # Check provider state before update attempt
      {:ok, game_before} = GameSession.lookup_game_session(game.uuid)
      assert game_before.provider.id == :spotify
      assert game_before.provider.meta == nil

      {:ok, _, socket} = join_room_channel(current_user, game.uuid)

      ref =
        push(socket, "update_provider", %{"device_id" => "test-device-id"})

      refute_reply ref, :ok
      refute_broadcast "provider_updated", _

      # Verify provider state remained unchanged
      {:ok, game_after} = GameSession.lookup_game_session(game.uuid)
      assert game_after.provider.id == :spotify
      assert game_after.provider.meta == nil

      GameSession.end_game_session(game.uuid)
    end

    test "allows owner access to whitelisted provider", %{current_user: current_user} do
      {:ok, game} = GameSession.create_game_session(current_user.uuid, :spotify)

      # Check provider state before update
      {:ok, game_before} = GameSession.lookup_game_session(game.uuid)
      assert game_before.provider.id == :spotify
      assert game_before.provider.meta == nil

      {:ok, _, socket} = join_room_channel(current_user, game.uuid)

      ref =
        push(socket, "update_provider", %{"device_id" => "test-device-id"})

      assert_reply ref, :ok, %{}
      refute_broadcast "provider_updated", _

      # Verify provider state was updated
      {:ok, game_after} = GameSession.lookup_game_session(game.uuid)
      assert game_after.provider.id == :spotify
      assert game_after.provider.meta.device_id == "test-device-id"

      GameSession.end_game_session(game.uuid)
    end

    test "transfer playback to device", %{current_user: current_user} do
      provider = Provider.new(:spotify, %{device_id: "test-device-id"})
      {:ok, game} = GameSession.create_game_session(current_user.uuid, :spotify)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid, %{provider: provider})

      Repatch.patch(Songy.Boundary.Spotify, :transfer_playback, [mode: :shared], fn _provider, payload ->
        assert payload == %{"device_id" => "test-device-id"}

        {:ok, :playback_transferred}
      end)

      Repatch.allow(self(), socket.channel_pid)

      ref = push(socket, "update_provider", %{"device_id" => "test-device-id"})

      assert_reply ref, :ok
      assert Repatch.called?(Songy.Boundary.Spotify, :transfer_playback, 2, by: socket.channel_pid)

      GameSession.end_game_session(game.uuid)
    end
  end

  describe "get_spotify_token event" do
    test "returns access token when provider is available", %{current_user: current_user} do
      provider = Provider.new(:spotify, %{access_token: "spotify_access_token_123"})
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid, %{provider: provider})

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :ok, %{token: "spotify_access_token_123"}

      GameSession.end_game_session(game.uuid)
    end

    test "returns error when provider has no access_token", %{current_user: current_user} do
      provider = Provider.new(:spotify, %{refresh_token: "refresh_token_123"})

      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid, %{provider: provider})

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}

      GameSession.end_game_session(game.uuid)
    end

    test "returns error with missing access_token", %{current_user: current_user} do
      provider = Provider.new(:spotify, %{access_token: nil})

      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid, %{provider: provider})

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}

      GameSession.end_game_session(game.uuid)
    end

    test "returns error when provider is nil", %{current_user: current_user} do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid, %{provider: nil})

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}

      GameSession.end_game_session(game.uuid)
    end

    test "returns error when provider is unknown", %{current_user: current_user} do
      provider = Provider.new(:youtube, %{access_token: "youtube_token_123"})

      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid, %{provider: provider})

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}

      GameSession.end_game_session(game.uuid)
    end

    test "returns error with missing provider", %{current_user: current_user} do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid)

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}

      GameSession.end_game_session(game.uuid)
    end
  end

  describe "next_phase event" do
    test "advances game phase and broadcasts state update", %{current_user: current_user} do
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

      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}

      {:ok, game} = GameSession.create_game_session("owner123", :spotify)
      :ok = GameSession.set_credentials(game.uuid, credentials)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      # Start the game to get it to in_progress status
      {:ok, _, socket} = join_room_channel(current_user, game.uuid)
      push(socket, "start_game", %{})

      # Wait for game to start
      assert_broadcast "state_updated", %{status: :in_progress}

      # Send next_phase event
      ref = push(socket, "next_phase", %{})

      assert_reply ref, :ok
      assert_broadcast "state_updated", %{turn: %{phase: :ready}}

      GameSession.end_game_session(game.uuid)
    end

    test "fails when game session does not exist", %{current_user: current_user} do
      {:ok, _, socket} = join_room_channel(current_user, "nonexistent")

      ref = push(socket, "next_phase", %{})

      refute_reply ref, :ok
    end

    test "fails when game is not in progress", %{current_user: current_user} do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid)

      ref = push(socket, "next_phase", %{})

      refute_reply ref, :ok

      GameSession.end_game_session(game.uuid)
    end
  end

  describe "make_assumption event" do
    test "makes user assumption and broadcasts state update", %{current_user: current_user} do
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

      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      :ok = GameSession.set_credentials(game.uuid, credentials)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)
      Repatch.allow(self(), pid)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid)

      push(socket, "start_game", %{})

      current_user_uuid = current_user.uuid

      assert_broadcast "state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: track, phase: :waiting},
        timelines: %{
          ^current_user_uuid => [initial_track]
        }
      }

      push(socket, "next_phase", %{})

      assert_broadcast "state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: ^track, phase: :ready}
      }

      push(socket, "make_assumption", %{"position" => 0})

      assert_broadcast "state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: ^track, phase: :steady, timeline: [^track, ^initial_track]}
      }

      GameSession.end_game_session(game.uuid)
    end

    test "handles error gracefully when game session does not exist", %{current_user: current_user} do
      {:ok, _, socket} = join_room_channel(current_user, "nonexistent")

      push(socket, "make_assumption", %{"position" => 0})

      refute_broadcast "state_updated", _
    end
  end

  describe "reorder_timeline event" do
    test "reorders user timeline and broadcasts state update", %{current_user: current_user} do
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

      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      credentials = %Songy.Core.Provider.Spotify{access_token: "test-token"}
      :ok = GameSession.set_credentials(game.uuid, credentials)

      [{pid, _}] = Registry.lookup(Songy.Registry, game.uuid)

      Repatch.allow(self(), pid)

      {:ok, _, socket} = join_room_channel(current_user, game.uuid)

      push(socket, "start_game", %{})

      current_user_uuid = current_user.uuid

      assert_broadcast "state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: track, phase: :waiting},
        timelines: %{
          ^current_user_uuid => [initial_track]
        }
      }

      push(socket, "next_phase", %{})

      assert_broadcast "state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: ^track, phase: :ready}
      }

      push(socket, "make_assumption", %{"position" => 0})

      assert_broadcast "state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: ^track, phase: :steady, timeline: [^track, ^initial_track]}
      }

      push(socket, "reorder_timeline", %{"position" => 0})

      assert_broadcast "state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: ^track, phase: :steady},
        timelines: %{
          ^current_user_uuid => [^initial_track]
        }
      }

      GameSession.end_game_session(game.uuid)
    end

    test "handles error gracefully when game session does not exist", %{current_user: current_user} do
      {:ok, _, socket} = join_room_channel(current_user, "nonexistent")

      push(socket, "reorder_timeline", %{"position" => 0})

      refute_broadcast "state_updated", _
    end
  end
end
