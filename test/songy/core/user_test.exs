defmodule Songy.Core.UserTest do
  use ExUnit.Case, async: true

  alias Songy.Core.User

  describe "new/0" do
    test "creates user with id" do
      user = User.new()

      assert %User{} = user
      assert is_binary(user.id)
      assert String.length(user.id) == 32
      assert String.match?(user.id, ~r/^[0-9a-f]{32}$/)
    end

    test "creates user with generated fields" do
      user = User.new()

      assert is_binary(user.name)
      assert is_binary(user.avatar_url)
      assert String.contains?(user.avatar_url, "dicebear.com")
      assert String.contains?(user.avatar_url, user.id)
    end

    test "generates unique ids" do
      user1 = User.new()
      user2 = User.new()

      assert user1.id != user2.id
    end
  end
end
