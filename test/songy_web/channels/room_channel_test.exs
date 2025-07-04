defmodule SongyWeb.RoomChannelTest do
  use SongyWeb.ChannelCase

  alias Songy.Boundary.GameSession

  setup do
    current_user = Songy.Core.User.get_user("test-uuid")

    {:ok, reply, socket} =
      SongyWeb.UserSocket
      |> socket("user_id", %{current_user_uuid: current_user.uuid})
      |> subscribe_and_join(SongyWeb.RoomChannel, "room:lobby")

    %{socket: socket, current_user: current_user, join_reply: reply}
  end

  test "join succeeds", %{join_reply: reply} do
    assert reply == %{}
  end

  describe "start_game event" do
    test "changes game status and broadcasts update", %{current_user: current_user} do
      {:ok, game} = GameSession.create_game_session("owner123")
      {:ok, _updated_game} = GameSession.add_participant(game.uuid, current_user.uuid)

      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:#{game.uuid}")

      push(socket, "start_game", %{})

      assert_broadcast "state_updated", %{status: :in_progress}

      {:ok, updated_game} = GameSession.get_game_session(game.uuid)
      assert updated_game.status == :in_progress

      GameSession.end_game_session(game.uuid)
    end

    test "fails when game session does not exist", %{current_user: current_user} do
      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:nonexistent")

      push(socket, "start_game", %{})

      refute_push "start_game", _
      refute_broadcast "state_updated", _
    end
  end

  describe "get_spotify_token event" do
    test "returns spotify access token when provider is available", %{current_user: current_user} do
      provider = %Songy.Core.Provider{
        id: :spotify,
        meta: %{access_token: "spotify_access_token_123"}
      }

      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid, provider: provider})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:lobby")

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :ok, %{token: "spotify_access_token_123"}
    end

    test "returns error when provider is nil", %{current_user: current_user} do
      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid, provider: nil})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:lobby")

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}
    end

    test "returns error when provider is not spotify", %{current_user: current_user} do
      provider = %Songy.Core.Provider{
        id: :youtube,
        meta: %{access_token: "youtube_token_123"}
      }

      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid, provider: provider})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:lobby")

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}
    end

    test "returns error when spotify provider has no access_token", %{current_user: current_user} do
      provider = %Songy.Core.Provider{
        id: :spotify,
        meta: %{refresh_token: "refresh_token_123"}
      }

      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid, provider: provider})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:lobby")

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}
    end

    test "returns error when spotify provider has nil access_token", %{current_user: current_user} do
      provider = %Songy.Core.Provider{
        id: :spotify,
        meta: %{access_token: nil}
      }

      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid, provider: provider})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:lobby")

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}
    end

    test "returns error when no provider is assigned", %{current_user: current_user} do
      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:lobby")

      ref = push(socket, "get_spotify_token", %{})

      assert_reply ref, :error, %{reason: "invalid_credentials"}
    end
  end

  describe "participant events" do
    test "handles participant_joined event", %{current_user: current_user} do
      {:ok, game} = GameSession.create_game_session("owner123")

      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:#{game.uuid}")

      # Simulate a participant_joined event
      send(socket.channel_pid, {:participant_joined, current_user.uuid})

      user_uuid = current_user.uuid
      assert_broadcast "state_updated", %{participants: [%{uuid: ^user_uuid}]}

      {:ok, updated_game} = GameSession.get_game_session(game.uuid)
      assert length(updated_game.participants) == 1
      assert Enum.any?(updated_game.participants, &(&1.uuid == current_user.uuid))

      GameSession.end_game_session(game.uuid)
    end

    test "handles participant_left event", %{current_user: current_user} do
      {:ok, game} = GameSession.create_game_session("owner123")
      {:ok, _updated_game} = GameSession.add_participant(game.uuid, current_user.uuid)

      # Verify participant was added
      {:ok, game_before_leave} = GameSession.get_game_session(game.uuid)
      assert length(game_before_leave.participants) == 1

      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:#{game.uuid}")

      # Simulate a participant_left event
      send(socket.channel_pid, {:participant_left, current_user.uuid})

      assert_broadcast "state_updated", game_state

      # Verify broadcast contains expected state
      assert length(game_state.participants) == 0

      GameSession.end_game_session(game.uuid)
    end

    test "handles participant_joined event with nonexistent game", %{current_user: current_user} do
      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:nonexistent")

      # Simulate a participant_joined event
      send(socket.channel_pid, {:participant_joined, current_user.uuid})

      refute_broadcast "state_updated", _
    end

    test "handles participant_left event with nonexistent game", %{current_user: current_user} do
      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:nonexistent")

      # Simulate a participant_left event
      send(socket.channel_pid, {:participant_left, current_user.uuid})

      refute_broadcast "state_updated", _
    end
  end
end
