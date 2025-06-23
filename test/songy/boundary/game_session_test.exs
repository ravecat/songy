defmodule Songy.Boundary.GameSessionTest do
  use ExUnit.Case, async: true
  use Repatch.ExUnit
  use AssertEventually

  alias Songy.Boundary.GameSession
  alias Songy.Core.Game

  describe "start_game/1" do
    test "starts new game session process" do
      game = Game.new()

      assert {:ok, pid} = GameSession.start_game(game)
      assert Process.alive?(pid)
      assert [{^pid, nil}] = Registry.lookup(Songy.Registry, game.uuid)
    end

    test "returns error when starting duplicate game session" do
      game = Game.new()

      assert {:ok, _pid1} = GameSession.start_game(game)
      assert {:error, {:already_started, _pid}} = GameSession.start_game(game)
    end

    test "multiple different games can be started" do
      game1 = Game.new()
      game2 = Game.new()

      assert {:ok, pid1} = GameSession.start_game(game1)
      assert {:ok, pid2} = GameSession.start_game(game2)

      assert Process.alive?(pid1)
      assert Process.alive?(pid2)
      assert pid1 != pid2
    end
  end

  describe "add_user/2" do
    setup do
      game = Game.new()
      {:ok, pid} = GameSession.start_game(game)

      %{game: game, pid: pid}
    end

    test "adds user to game session", %{game: game} do
      user_uuid = "user123"

      assert {:ok, updated_game} = GameSession.add_user(game.uuid, user_uuid)
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == user_uuid
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = GameSession.add_user("nonexistent", "user123")
    end

    test "returns error when game is full", %{game: _game} do
      small_game = Game.new(1)
      {:ok, _pid} = GameSession.start_game(small_game)

      assert {:ok, _updated_game} = GameSession.add_user(small_game.uuid, "user1")
      assert {:error, :game_full} = GameSession.add_user(small_game.uuid, "user2")
    end

    test "returns error when user already joined", %{game: game} do
      user_uuid = "user123"

      assert {:ok, _updated_game} = GameSession.add_user(game.uuid, user_uuid)
      assert {:error, :user_already_joined} = GameSession.add_user(game.uuid, user_uuid)
    end

    test "handles concurrent user additions", %{game: _game} do
      limited_game = Game.new(3)
      {:ok, _pid} = GameSession.start_game(limited_game)

      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            GameSession.add_user(limited_game.uuid, "user#{i}")
          end)
        end

      results = Task.await_many(tasks)
      successful = Enum.count(results, &match?({:ok, _}, &1))
      failed = Enum.count(results, &match?({:error, :game_full}, &1))

      assert successful <= 3
      assert successful + failed == 5
    end
  end

  describe "end_game/1" do
    test "terminates game session process" do
      game = Game.new()
      {:ok, _} = GameSession.start_game(game)

      assert :ok = GameSession.end_game(game.uuid)
      assert_eventually [] = Registry.lookup(Songy.Registry, game.uuid)
    end

    test "handles termination of non-existent session" do
      assert :ok = GameSession.end_game("nonexistent")
    end
  end
end
