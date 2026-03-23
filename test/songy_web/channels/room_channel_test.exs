defmodule SongyWeb.RoomChannelTest do
  use SongyWeb.ChannelCase

  alias Songy.Boundary.GameSession
  alias Songy.Core.Game
  alias Songy.Core.Turn
  alias Songy.Core.User
  alias SongyWeb.Presence

  defp join_room_channel(current_user, room_id, assigns \\ %{}) do
    default_assigns = %{current_user_id: current_user.uuid}

    SongyWeb.UserSocket
    |> socket("user_id", Map.merge(default_assigns, assigns))
    |> subscribe_and_join(SongyWeb.RoomChannel, "room:#{room_id}")
  end

  setup do
    current_user = User.get_user("test-uuid")
    owner = User.get_user("owner123")

    %{current_user: current_user, owner: owner}
  end

  # === JOIN EVENT ===

  describe "join" do
    test "tracks user presence on join", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      {:ok, _reply, socket} = join_room_channel(current_user, game_id)

      presence_list = Presence.list(socket)
      assert Map.has_key?(presence_list, current_user.uuid)
    end

    test "returns state in join reply", %{current_user: current_user} do
      game_id = "game-123"

      game_state = %Game{
        id: game_id,
        owner_id: "owner123",
        status: :waiting,
        queue: [],
        cursor: 0,
        turn: nil
      }

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, game_state}
      end)

      assert {:ok, %{game: ^game_state, permissions: _permissions}, _socket} =
               join_room_channel(current_user, game_id)

      refute_push "state", _
    end

    test "handles missing game session gracefully", %{current_user: current_user} do
      game_id = "invalid-game"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:error, :game_not_found}
      end)

      assert {:error, %{reason: "game_not_found"}} = join_room_channel(current_user, game_id)

      refute_push "state", _
    end
  end

  describe "state updates" do
    test "push state when channel receives a state message", %{current_user: current_user} do
      game_id = "game-123"

      initial_game = %Game{
        id: game_id,
        owner_id: "owner123",
        status: :waiting,
        queue: [],
        cursor: 0,
        turn: nil
      }

      updated_game = %Game{
        id: game_id,
        owner_id: "owner123",
        status: :in_progress,
        queue: [current_user.uuid],
        cursor: 0,
        turn: %Turn{phase: :waiting}
      }

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, initial_game}
      end)

      assert {:ok, %{game: ^initial_game, permissions: _permissions}, socket} =
               join_room_channel(current_user, game_id)

      refute_push "state", _

      send(socket.channel_pid, {:state, updated_game})

      assert_push "state", %{game: ^updated_game, permissions: _permissions}
    end
  end

  describe "timer updates" do
    test "pushes timer when channel receives a timer message", %{current_user: current_user} do
      game_id = "game-123"

      game_state = %Game{
        id: game_id,
        owner_id: "owner123",
        status: :in_progress,
        queue: [],
        cursor: 0,
        turn: %Turn{phase: :challenging}
      }

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, game_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      send(socket.channel_pid, {:timer, 7})

      assert_push "timer", %{remaining: 7}
    end
  end

  # === START_GAME EVENT ===

  describe "start_game" do
    test "does not reply when start_game succeeds", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      Repatch.patch(GameSession, :start_game_session, [mode: :shared], fn ^game_id, _user_id ->
        {:ok, %{status: :in_progress}}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "start_game", %{})

      refute_reply ref, :ok
    end

    test "does not reply when start_game fails", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      Repatch.patch(GameSession, :start_game_session, [mode: :shared], fn ^game_id, _user_id ->
        {:error, :start_game_failed}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "start_game", %{})

      refute_reply ref, :ok
    end
  end

  # === PLAYBACK EVENTS ===

  describe "start_playback" do
    test "replies :ok when start_playback succeeds", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid
      new_state = %{player: %{is_playback: true}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :in_progress,
           queue: [],
           cursor: 0,
           turn: %Turn{phase: :waiting}
         }}
      end)

      Repatch.patch(GameSession, :start_playback, [mode: :shared], fn ^game_id, ^user_id ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "start_playback", %{})

      assert_reply ref, :ok
    end

    test "does not reply when start_playback fails", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :in_progress,
           queue: [],
           cursor: 0,
           turn: %Turn{phase: :waiting}
         }}
      end)

      Repatch.patch(GameSession, :start_playback, [mode: :shared], fn ^game_id, ^user_id ->
        {:error, :unauthorized}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "start_playback", %{})

      refute_reply ref, :ok
    end
  end

  describe "pause_playback" do
    test "replies :ok when pause_playback succeeds", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid
      new_state = %{player: %{is_playback: false}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :in_progress,
           queue: [],
           cursor: 0,
           turn: %Turn{phase: :waiting}
         }}
      end)

      Repatch.patch(GameSession, :pause_playback, [mode: :shared], fn ^game_id, ^user_id ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "pause_playback", %{})

      assert_reply ref, :ok
    end

    test "does not reply when pause_playback fails", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :in_progress,
           queue: [],
           cursor: 0,
           turn: %Turn{phase: :waiting}
         }}
      end)

      Repatch.patch(GameSession, :pause_playback, [mode: :shared], fn ^game_id, ^user_id ->
        {:error, :unauthorized}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "pause_playback", %{})

      refute_reply ref, :ok
    end
  end

  # === ADVANCE_TURN EVENT ===

  describe "advance_turn" do
    test "replies :ok when advance_turn succeeds", %{current_user: current_user} do
      game_id = "game-123"
      new_state = %{turn: %{phase: :ready}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :in_progress,
           queue: [],
           cursor: 0,
           turn: %Turn{phase: :waiting}
         }}
      end)

      Repatch.patch(GameSession, :advance_turn, [mode: :shared], fn ^game_id, _user_id ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "advance_turn", %{})

      assert_reply ref, :ok
    end

    test "does not reply when advance_turn fails", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      Repatch.patch(GameSession, :advance_turn, [mode: :shared], fn ^game_id, _user_id ->
        {:error, :game_not_started}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "advance_turn", %{})

      refute_reply ref, :ok
    end
  end

  describe "get_provider" do
    test "returns token when provider found", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn ^user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: "test-token",
           refresh_token: "test-refresh",
           device_id: nil,
           expires_at: DateTime.utc_now()
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "get_provider", %{})

      assert_reply ref, :ok, %{token: "test-token"}
    end

    test "returns error when provider not found", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn ^user_id ->
        {:error, :provider_not_found}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "get_provider", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}
    end

    test "returns error when access token is nil", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn ^user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: nil,
           refresh_token: "test-refresh",
           device_id: nil,
           expires_at: DateTime.utc_now()
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "get_provider", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}
    end
  end

  describe "update_provider" do
    test "updates provider when successful", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn ^user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: "old-token",
           refresh_token: "old-refresh",
           device_id: nil,
           expires_at: DateTime.utc_now()
         }}
      end)

      Repatch.patch(Songy.Providers, :update, [mode: :shared], fn ^user_id, _updated_provider ->
        :ok
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "update_provider", %{"access_token" => "new-token"})

      assert_reply ref, :ok
    end

    test "returns error when provider not found", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn ^user_id ->
        {:error, :provider_not_found}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "update_provider", %{"access_token" => "new-token"})

      assert_reply ref, :error, %{reason: "provider_not_found"}
    end
  end

  describe "get_current_user" do
    test "returns current user data", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "get_current_user", %{})
      assert_reply ref, :ok, %{uuid: user_uuid}
      assert user_uuid == current_user.uuid
    end
  end

  # === GAME ACTION EVENTS ===

  describe "make_assumption" do
    test "replies :ok when make_assumption succeeds", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid
      new_state = %{turn: %{assumptions: %{0 => user_id}}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :in_progress,
           queue: [],
           cursor: 0,
           turn: %Turn{phase: :challenging}
         }}
      end)

      Repatch.patch(GameSession, :make_assumption, [mode: :shared], fn ^game_id, ^user_id, 0 ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "make_assumption", %{"position" => 0})

      assert_reply ref, :ok
    end

    test "does not reply when make_assumption fails", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      Repatch.patch(GameSession, :make_assumption, [mode: :shared], fn ^game_id, ^user_id, 0 ->
        {:error, :not_in_challenging_phase}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "make_assumption", %{"position" => 0})

      refute_reply ref, :ok
    end

    test "returns error for missing position in payload", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :in_progress,
           queue: [],
           cursor: 0,
           turn: %Turn{phase: :waiting}
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      # Push with empty payload - pattern match fails, goes to generic handle_in
      ref = push(socket, "make_assumption", %{})

      assert_reply ref, :error
    end
  end

  # === ERROR HANDLING ===

  describe "unknown event" do
    test "returns error for unknown event", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok,
         %Game{
           id: game_id,
           owner_id: "owner123",
           status: :waiting,
           queue: [],
           cursor: 0,
           turn: nil
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)

      ref = push(socket, "unknown_event", %{})

      assert_reply ref, :error, %{reason: "unknown_event", event: "unknown_event"}
    end
  end
end
