defmodule Songy.Core.GameTest do
  use ExUnit.Case, async: true

  alias Songy
  alias Songy.Core.Game

  describe "create_game/1" do
    test "creates game with default max participants" do
      game = Songy.create_game()

      assert %Game{} = game
      assert game.max_participants == 6
      assert game.participants == []
      assert game.status == :waiting
      assert String.length(game.uuid) == 8
    end

    test "creates game with custom max participants" do
      game = Songy.create_game(4)

      assert game.max_participants == 4
    end
  end

  describe "join_game/2 and leave_game/2" do
    test "user can join and leave game" do
      game = Songy.create_game()
      user = Songy.create_user()

      # Join game
      assert {:ok, updated_game} = Songy.join_game(game, user)
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == user.uuid

      # Leave game
      assert {:ok, final_game} = Songy.leave_game(updated_game, user.uuid)
      assert length(final_game.participants) == 0
    end

    test "cannot join full game" do
      game = Songy.create_game(1)
      user1 = Songy.create_user()
      user2 = Songy.create_user()

      {:ok, game_with_user} = Songy.join_game(game, user1)
      assert {:error, :game_full} = Songy.join_game(game_with_user, user2)
    end

    test "cannot join same user twice" do
      game = Songy.create_game()
      user = Songy.create_user()

      {:ok, game_with_user} = Songy.join_game(game, user)
      assert {:error, :user_already_joined} = Songy.join_game(game_with_user, user)
    end
  end

  describe "can_join_game?/2" do
    test "returns true when user can join" do
      game = Songy.create_game()
      user = Songy.create_user()

      assert Songy.can_join_game?(game, user) == true
    end

    test "returns false when game is full" do
      game = Songy.create_game(1)
      user1 = Songy.create_user()
      user2 = Songy.create_user()

      {:ok, full_game} = Songy.join_game(game, user1)

      assert Songy.can_join_game?(full_game, user2) == false
    end

    test "returns false when user already joined" do
      game = Songy.create_game()
      user = Songy.create_user()

      {:ok, game_with_user} = Songy.join_game(game, user)

      assert Songy.can_join_game?(game_with_user, user) == false
    end

    test "returns false when game is not waiting" do
      game = Songy.create_game() |> Songy.start_game()
      user = Songy.create_user()

      assert Songy.can_join_game?(game, user) == false
    end
  end
end
