defmodule SongyWeb.RoomChannelTest do
  use SongyWeb.ChannelCase

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
end
