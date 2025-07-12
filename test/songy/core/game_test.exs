defmodule Songy.Core.GameTest do
  use ExUnit.Case, async: true

  alias Songy.Core.{Game, User}

  describe "new/1" do
    test "creates game with default max participants" do
      owner_uuid = "owner123"
      game = Game.new(owner_uuid)

      assert %Game{} = game
      assert game.max_participants == 8
      assert game.participants == []
      assert game.status == :waiting
      assert game.owner_uuid == owner_uuid
      assert String.length(game.uuid) == 8
      assert %DateTime{} = game.created_at
    end
  end

  describe "new/2" do
    test "creates game with custom max participants" do
      owner_uuid = "owner456"
      game = Game.new(owner_uuid, max_participants: 4)

      assert game.max_participants == 4
      assert game.owner_uuid == owner_uuid
      assert game.participants == []
      assert game.status == :waiting
    end

    test "creates game with multiple options" do
      owner_uuid = "owner789"
      game = Game.new(owner_uuid, max_participants: 12)

      assert game.max_participants == 12
      assert game.owner_uuid == owner_uuid
      assert game.participants == []
      assert game.status == :waiting
    end

    test "creates game with empty options list" do
      owner_uuid = "owner000"
      game = Game.new(owner_uuid, [])

      assert game.max_participants == 8
      assert game.owner_uuid == owner_uuid
      assert game.participants == []
      assert game.status == :waiting
    end

    test "raises error with invalid max_participants" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", max_participants: 0)
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", max_participants: -1)
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", max_participants: "invalid")
      end
    end

    test "raises error with unknown options" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", created_at: DateTime.utc_now())
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", uuid: "custom_uuid")
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Game.new("owner123", unknown_field: "test")
      end
    end
  end

  describe "add_participant/2" do
    test "adds user to game successfully" do
      game = Game.new("owner123")
      user = User.new()

      assert {:ok, updated_game} = Game.add_participant(game, user)
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == user.uuid
    end

    test "returns error when game is full" do
      game = Game.new("owner123", max_participants: 1)
      user1 = User.new()
      user2 = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user1)
      assert {:error, :game_full} = Game.add_participant(game_with_user, user2)
    end

    test "returns error when user already joined" do
      game = Game.new("owner123")
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      assert {:error, :user_already_joined} = Game.add_participant(game_with_user, user)
    end
  end

  describe "remove_participant/2" do
    test "removes user from game successfully" do
      game = Game.new("owner123")
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      assert {:ok, updated_game} = Game.remove_participant(game_with_user, user.uuid)
      assert length(updated_game.participants) == 0
    end

    test "returns error when user not found" do
      game = Game.new("owner123")

      assert {:error, :user_not_found} = Game.remove_participant(game, "non_existent_uuid")
    end
  end

  describe "participant_count/1" do
    test "returns 0 for empty game" do
      game = Game.new("owner123")

      assert Game.participant_count(game) == 0
    end

    test "returns correct count with participants" do
      game = Game.new("owner123")
      user1 = User.new()
      user2 = User.new()

      {:ok, game_with_one} = Game.add_participant(game, user1)
      assert Game.participant_count(game_with_one) == 1

      {:ok, game_with_two} = Game.add_participant(game_with_one, user2)
      assert Game.participant_count(game_with_two) == 2
    end
  end

  describe "full?/1" do
    test "returns false for empty game" do
      game = Game.new("owner123", max_participants: 2)

      assert Game.full?(game) == false
    end

    test "returns false for partially filled game" do
      game = Game.new("owner123", max_participants: 2)
      user = User.new()

      {:ok, game_with_user} = Game.add_participant(game, user)
      assert Game.full?(game_with_user) == false
    end

    test "returns true for full game" do
      game = Game.new("owner123", max_participants: 1)
      user = User.new()

      {:ok, full_game} = Game.add_participant(game, user)
      assert Game.full?(full_game) == true
    end
  end

  describe "update_status/2" do
    test "updates status to in_progress" do
      game = Game.new("owner123")

      updated_game = Game.update_status(game, :in_progress)
      assert updated_game.status == :in_progress
    end

    test "updates status to finished" do
      game = Game.new("owner123")

      updated_game = Game.update_status(game, :finished)
      assert updated_game.status == :finished
    end

    test "updates status back to waiting" do
      game = Game.new("owner123")
      |> Game.update_status(:in_progress)

      updated_game = Game.update_status(game, :waiting)
      assert updated_game.status == :waiting
    end
  end

  describe "owner?/2" do
    test "returns true when user is owner" do
      owner_uuid = "owner123"
      game = Game.new(owner_uuid)

      assert Game.owner?(game, owner_uuid) == true
    end

    test "returns false when user is not owner" do
      game = Game.new("owner123")

      assert Game.owner?(game, "other456") == false
    end
  end
end
