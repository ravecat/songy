defmodule SongyWeb.RoomChannelTest do
  use SongyWeb.ChannelCase

  setup do
    current_user = Songy.Core.User.get_user("test-uuid")

    {:ok, reply, socket} =
      SongyWeb.UserSocket
      |> socket("user_id", %{current_user: current_user})
      |> subscribe_and_join(SongyWeb.RoomChannel, "room:lobby")

    %{socket: socket, current_user: current_user, join_reply: reply}
  end

  test "join returns current_user data", %{join_reply: reply, current_user: current_user} do
    assert reply.current_user.uuid == current_user.uuid
    assert reply.current_user.name == current_user.name
    assert reply.current_user.avatar_url == current_user.avatar_url
  end
end
