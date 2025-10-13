defmodule SongyWeb.RoomChannelTest do
  use SongyWeb.ChannelCase

  alias Songy.Boundary.GameSession
  alias Songy.Core.User

  defp join_room_channel(current_user, room_uuid, assigns \\ %{}) do
    default_assigns = %{current_user_uuid: current_user.uuid}

    SongyWeb.UserSocket
    |> socket("user_id", Map.merge(default_assigns, assigns))
    |> subscribe_and_join(SongyWeb.RoomChannel, "room:#{room_uuid}")
  end

  setup do
    current_user = User.get_user("test-uuid")
    owner = User.get_user("owner123")

    {:ok, game} = GameSession.create_game_session(owner.uuid)

    Repatch.patch(
      Songy.Boundary.Spotify,
      :search_random_track,
      [mode: :shared],
      fn _credentials ->
        {:ok,
         %Spotify.Track{
           name: "Random Song",
           artists: [%{"name" => "Random Artist"}],
           album: %{
             "release_date" => "2023-01-01",
             "images" => [%{"url" => "https://example.com/cover.jpg"}]
           }
         }}
      end
    )

    [{pid, _}] = Registry.lookup(Songy.Registry, game.id)

    Repatch.allow(self(), pid)

    %{current_user: current_user, owner: owner, game: game}
  end

  describe "channel join" do
    test "handles join succeeds", %{current_user: current_user, game: game} do
      {:ok, reply, _socket} = join_room_channel(current_user, game.id)
      assert reply == %{}
    end
  end

  describe "start_game event" do
    test "changes game status and broadcasts update", %{current_user: current_user, game: game} do
      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn _registry, _user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: "test-token",
           refresh_token: "test-refresh-token"
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game.id)

      push(socket, "start_game", %{})

      assert_broadcast("state_updated", %{status: :in_progress})

      {:ok, updated_game} = GameSession.lookup_game_session(game.id)
      assert updated_game.status == :in_progress
    end

    test "fails when game session does not exist", %{current_user: current_user} do
      {:ok, _, socket} = join_room_channel(current_user, "nonexistent")

      push(socket, "start_game", %{})

      refute_push("start_game", _)
      refute_broadcast("state_updated", _)
    end
  end

  describe "get_spotify_token event" do
    test "returns access token when provider is available", %{
      current_user: current_user,
      game: game
    } do
      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn _registry, _user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: "spotify_access_token_123",
           refresh_token: "test-refresh-token"
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game.id)

      ref = push(socket, "get_spotify_token", %{})

      assert_reply(ref, :ok, %{token: "spotify_access_token_123"})
    end

    test "returns error when provider has no access_token", %{
      current_user: current_user,
      game: game
    } do
      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn _registry, _user_id ->
        {:ok, %Songy.Core.Provider.Apple{}}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game.id)

      ref = push(socket, "get_spotify_token", %{})

      assert_reply(ref, :error, %{reason: "invalid_credentials"})
    end

    test "returns error", %{current_user: current_user, game: game} do
      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn _registry, _user_id ->
        {:error, :not_found}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game.id)

      ref = push(socket, "get_spotify_token", %{})

      assert_reply(ref, :error, %{reason: "invalid_credentials"})
    end
  end

  describe "update_provider event" do
    test "updates provider data with new payload", %{current_user: current_user, game: game} do
      initial_provider = %Songy.Core.Provider.Spotify{
        access_token: "token123",
        refresh_token: "refresh456",
        expires_at: DateTime.utc_now()
      }

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn _registry, _user_id ->
        {:ok, initial_provider}
      end)

      Repatch.patch(Songy.Providers, :update, [mode: :shared], fn _registry,
                                                                  user_id,
                                                                  updated_provider ->
        assert user_id == current_user.uuid
        assert %Songy.Core.Provider.Spotify{} = updated_provider
        assert updated_provider.device_id == "test-device-123"
        :ok
      end)

      {:ok, _, socket} = join_room_channel(current_user, game.id)

      ref = push(socket, "update_provider", %{"device_id" => "test-device-123"})

      assert_reply(ref, :ok)
    end

    test "returns error when user not found in ETS", %{current_user: current_user, game: game} do
      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn _registry, _user_id ->
        {:error, :not_found}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game.id)

      ref = push(socket, "update_provider", %{"device_id" => "test-device-123"})

      assert_reply(ref, :error, %{reason: "provider_not_found"})
    end
  end

  describe "next_phase event" do
    test "advances game phase and broadcasts state update", %{
      current_user: current_user,
      game: game
    } do
      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn _registry, _user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: "test-token",
           refresh_token: "test-refresh-token"
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game.id)

      push(socket, "start_game", %{})

      # Wait for game to start
      assert_broadcast("state_updated", %{status: :in_progress})

      # Send next_phase event
      ref = push(socket, "next_phase", %{})

      assert_reply(ref, :ok)
      assert_broadcast("state_updated", %{turn: %{phase: :ready}})
    end

    test "fails when game session does not exist", %{current_user: current_user} do
      {:ok, _, socket} = join_room_channel(current_user, "nonexistent")

      ref = push(socket, "next_phase", %{})

      refute_reply(ref, :ok)
    end

    test "fails when game is not in progress", %{current_user: current_user, game: game} do
      {:ok, _, socket} = join_room_channel(current_user, game.id)

      ref = push(socket, "next_phase", %{})

      refute_reply(ref, :ok)
    end
  end

  describe "make_assumption event" do
    test "makes user assumption and broadcasts state update", %{
      current_user: current_user,
      game: game
    } do
      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn _registry, _user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: "test-token",
           refresh_token: "test-refresh-token"
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game.id)

      push(socket, "start_game", %{})

      current_user_uuid = current_user.uuid

      assert_broadcast("state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: track, phase: :waiting},
        timelines: %{
          ^current_user_uuid => [initial_track]
        }
      })

      push(socket, "next_phase", %{})

      assert_broadcast("state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: ^track, phase: :ready}
      })

      push(socket, "make_assumption", %{"position" => 0})

      assert_broadcast("state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: ^track, phase: :steady, timeline: [^track, ^initial_track]}
      })
    end

    test "handles error gracefully when game session does not exist", %{
      current_user: current_user
    } do
      {:ok, _, socket} = join_room_channel(current_user, "nonexistent")

      push(socket, "make_assumption", %{"position" => 0})

      refute_broadcast("state_updated", _)
    end
  end

  describe "reorder_timeline event" do
    test "reorders user timeline and broadcasts state update", %{
      current_user: current_user,
      game: game
    } do
      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn _registry, _user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: "test-token",
           refresh_token: "test-refresh-token"
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game.id)

      push(socket, "start_game", %{})

      current_user_uuid = current_user.uuid

      assert_broadcast("state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: track, phase: :waiting},
        timelines: %{
          ^current_user_uuid => [initial_track]
        }
      })

      push(socket, "next_phase", %{})

      assert_broadcast("state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: ^track, phase: :ready}
      })

      push(socket, "make_assumption", %{"position" => 0})

      assert_broadcast("state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: ^track, phase: :steady, timeline: [^track, ^initial_track]}
      })

      push(socket, "reorder_timeline", %{"position" => 0})

      assert_broadcast("state_updated", %Songy.Core.Game{
        status: :in_progress,
        turn: %{track: ^track, phase: :steady},
        timelines: %{
          ^current_user_uuid => [^initial_track]
        }
      })
    end

    test "handles error gracefully when game session does not exist", %{
      current_user: current_user
    } do
      {:ok, _, socket} = join_room_channel(current_user, "nonexistent")

      push(socket, "reorder_timeline", %{"position" => 0})

      refute_broadcast("state_updated", _)
    end
  end
end
