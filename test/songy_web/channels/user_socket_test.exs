defmodule SongyWeb.UserSocketTest do
  use SongyWeb.ChannelCase

  alias Songy.Core.User
  alias SongyWeb.UserSocket

  describe "connect/3 with user_token" do
    test "connects successfully with valid user token" do
      user = User.new()
      user_token = Phoenix.Token.sign(SongyWeb.Endpoint, "current_user", user.id)

      assert {:ok, socket} = connect(UserSocket, %{"user_token" => user_token})
      assert socket.assigns.current_user_id == user.id
    end

    test "connects with valid user token" do
      user = User.new()

      user_token = Phoenix.Token.sign(SongyWeb.Endpoint, "current_user", user.id)

      params = %{
        "user_token" => user_token
      }

      assert {:ok, socket} = connect(UserSocket, params)
      assert socket.assigns.current_user_id == user.id
    end

    test "rejects connection with invalid user token" do
      invalid_token = "invalid_token_123"

      assert :error = connect(UserSocket, %{"user_token" => invalid_token})
    end

    test "rejects connection with expired user token" do
      user = User.new()

      expired_token =
        Phoenix.Token.sign(SongyWeb.Endpoint, "current_user", user.id, signed_at: System.system_time(:second) - 90000)

      assert :error = connect(UserSocket, %{"user_token" => expired_token})
    end
  end

  describe "connect/3 without user_token" do
    test "rejects connection when user_token is missing" do
      assert :error = connect(UserSocket, %{})
    end

    test "rejects connection when user_token is nil" do
      assert :error = connect(UserSocket, %{"user_token" => nil})
    end
  end

  describe "id/1" do
    test "returns user socket id based on current_user_id" do
      user = User.new()
      user_token = Phoenix.Token.sign(SongyWeb.Endpoint, "current_user", user.id)

      {:ok, socket} = connect(UserSocket, %{"user_token" => user_token})

      assert UserSocket.id(socket) == "user_socket:#{user.id}"
    end
  end
end
