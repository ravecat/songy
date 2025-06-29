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
      {:ok, game} = GameSession.create_game_session()
      {:ok, _updated_game} = GameSession.add_participant(game.uuid, current_user.uuid)

      {:ok, _, socket} =
        SongyWeb.UserSocket
        |> socket("user_id", %{current_user_uuid: current_user.uuid})
        |> subscribe_and_join(SongyWeb.RoomChannel, "room:#{game.uuid}")

      push(socket, "start_game", %{})

      assert_broadcast "game_state", %{status: :in_progress}

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
      refute_broadcast "game_state", _
    end
  end
end
