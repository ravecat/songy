defmodule Songy.Boundary.GameSessionTest do
  use ExUnit.Case, async: true
  use Repatch.ExUnit
  use AssertEventually

  alias Songy.Boundary.GameSession

  describe "start_game_session/0" do
    test "starts new game session process" do
      assert {:ok, game} = GameSession.start_game_session()

      pid =
        case Registry.lookup(Songy.Registry, game.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      assert Process.alive?(pid)
      assert game.uuid != nil
      assert game.participants == []
    end

    test "multiple different games can be started" do
      assert {:ok, game1} = GameSession.start_game_session()
      assert {:ok, game2} = GameSession.start_game_session()

      pid1 =
        case Registry.lookup(Songy.Registry, game1.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      pid2 =
        case Registry.lookup(Songy.Registry, game2.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      assert Process.alive?(pid1)
      assert Process.alive?(pid2)
      assert pid1 != pid2
      assert game1.uuid != game2.uuid
    end
  end

  describe "add_participant/2" do
    setup do
      {:ok, game} = GameSession.start_game_session()

      pid =
        case Registry.lookup(Songy.Registry, game.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      %{game: game, pid: pid}
    end

    test "adds participant to game session", %{game: game} do
      participant_uuid = "user123"

      assert {:ok, updated_game} = GameSession.add_participant(game.uuid, participant_uuid)
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == participant_uuid
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = GameSession.add_participant("nonexistent", "user123")
    end

    test "returns error when game is full", %{game: _game} do
      # Create a game with default max participants (8)
      {:ok, small_game} = GameSession.start_game_session()

      # Add participants up to max capacity
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user1")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user2")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user3")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user4")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user5")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user6")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user7")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user8")

      # Try to add 9th participant (should fail since max is 8)
      assert {:error, :game_full} = GameSession.add_participant(small_game.uuid, "user9")
    end

    test "returns error when participant already joined", %{game: game} do
      participant_uuid = "user123"

      assert {:ok, _updated_game} = GameSession.add_participant(game.uuid, participant_uuid)

      assert {:error, :user_already_joined} =
               GameSession.add_participant(game.uuid, participant_uuid)
    end

    test "handles concurrent participant additions", %{game: _game} do
      {:ok, limited_game} = GameSession.start_game_session()

      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            GameSession.add_participant(limited_game.uuid, "user#{i}")
          end)
        end

      results = Task.await_many(tasks)
      # Since we're using a normal game (max 6), all 5 should succeed
      successful = Enum.count(results, &match?({:ok, _}, &1))
      failed = Enum.count(results, &match?({:error, _}, &1))

      assert successful == 5
      assert failed == 0
    end
  end

  describe "end_game_session/1" do
    test "terminates game session process" do
      {:ok, game} = GameSession.start_game_session()

      assert :ok = GameSession.end_game_session(game.uuid)
      assert_eventually([] = Registry.lookup(Songy.Registry, game.uuid))
    end

    test "handles termination of non-existent session" do
      assert :ok = GameSession.end_game_session("nonexistent")
    end
  end

  describe "remove_participant/2" do
    setup do
      {:ok, game} = GameSession.start_game_session()

      pid =
        case Registry.lookup(Songy.Registry, game.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      %{game: game, pid: pid}
    end

    test "removes participant from game session", %{game: game} do
      participant_uuid = "user123"

      # Add participant first
      assert {:ok, game_with_participant} =
               GameSession.add_participant(game.uuid, participant_uuid)

      assert length(game_with_participant.participants) == 1

      # Remove participant
      assert {:ok, updated_game} = GameSession.remove_participant(game.uuid, participant_uuid)
      assert length(updated_game.participants) == 0
    end

    test "returns error when removing non-existent participant", %{game: game} do
      assert {:error, :user_not_found} = GameSession.remove_participant(game.uuid, "nonexistent")
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = GameSession.remove_participant("nonexistent", "user123")
    end
  end

  describe "get_game_session/1" do
    setup do
      {:ok, game} = GameSession.start_game_session()

      pid =
        case Registry.lookup(Songy.Registry, game.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      %{game: game, pid: pid}
    end

    test "returns current game state", %{game: game} do
      assert {:ok, returned_game} = GameSession.get_game_session(game.uuid)
      assert returned_game.uuid == game.uuid
      assert returned_game.participants == []
      assert returned_game.status == :waiting
    end

    test "returns updated game state after participant addition", %{game: game} do
      participant_uuid = "user123"
      {:ok, _} = GameSession.add_participant(game.uuid, participant_uuid)

      assert {:ok, updated_game} = GameSession.get_game_session(game.uuid)
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == participant_uuid
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = GameSession.get_game_session("nonexistent")
    end
  end
end
