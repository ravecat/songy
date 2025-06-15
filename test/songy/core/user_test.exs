defmodule Songy.Core.UserTest do
  use ExUnit.Case, async: true

  alias Songy.Core.User

  describe "new/0" do
    test "creates user with uuid" do
      user = User.new()

      assert %User{} = user
      assert is_binary(user.uuid)
      assert String.length(user.uuid) == 32
      assert String.match?(user.uuid, ~r/^[0-9a-f]{32}$/)
    end

    test "generates unique uuids" do
      user1 = User.new()
      user2 = User.new()

      assert user1.uuid != user2.uuid
    end
  end
end
