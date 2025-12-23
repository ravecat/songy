defmodule Songy.Boundary.GameTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Game
  alias Songy.Boundary.Turn
  alias Songy.Core.User

  setup %{test: test} do
    owner = %User{uuid: "owner-1", name: "Owner"}
    game_id = to_string(test)

    {:ok, _pid} = start_supervised({Turn, id: game_id})
    {:ok, _pid} = start_supervised({Game, id: game_id, owner_id: owner.uuid})

    %{game_id: game_id, owner: owner}
  end

  describe "initialization" do
    test "starts in :waiting state with correct defaults", %{game_id: game_id, owner: owner} do
      {:ok, game} = Game.get_state(game_id)

      assert game.id == game_id
      assert game.owner_id == owner.uuid
      assert game.status == :waiting
      assert game.participants == []
      assert game.max_participants == 10
      assert game.max_score == 10
      assert game.scores == %{}
      assert game.turn == nil
    end

    test "accepts custom max_participants and max_score", %{game_id: game_id} do
      custom_owner = %User{uuid: "custom-owner", name: "CustomOwner"}
      custom_game_id = "#{game_id}-custom"

      {:ok, _pid} = start_supervised({Turn, id: custom_game_id})

      {:ok, _pid} =
        start_supervised(
          {Game, id: custom_game_id, owner_id: custom_owner.uuid, max_participants: 4, max_score: 5},
          id: {:game_test, custom_game_id}
        )

      {:ok, game} = Game.get_state(custom_game_id)

      assert game.max_participants == 4
      assert game.max_score == 5
    end
  end

  describe ":waiting state - add_participant" do
    test "adds participant successfully", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      assert {:ok, game} = Game.add_participant(game_id, user1)

      assert length(game.participants) == 1
      assert hd(game.participants).uuid == user1.uuid
      assert game.scores[user1.uuid] == 0
      assert game.status == :waiting
    end

    test "adds multiple participants", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      {:ok, _} = Game.add_participant(game_id, user1)
      {:ok, game} = Game.add_participant(game_id, user2)

      assert length(game.participants) == 2
      assert game.scores[user1.uuid] == 0
      assert game.scores[user2.uuid] == 0
    end

    test "rejects duplicate participants", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      {:ok, _} = Game.add_participant(game_id, user1)
      assert {:error, :already_joined} = Game.add_participant(game_id, user1)
    end

    test "rejects when game is full", %{game_id: game_id} do
      # Add max_participants (10) users
      users = for i <- 1..10, do: %User{uuid: "user-#{i}", name: "Player#{i}"}

      Enum.each(users, fn user ->
        {:ok, _} = Game.add_participant(game_id, user)
      end)

      # Try to add 11th user
      extra_user = %User{uuid: "user-11", name: "Player11"}
      assert {:error, :game_full} = Game.add_participant(game_id, extra_user)
    end
  end

  describe ":waiting state - remove_participant" do
    test "removes participant successfully", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      {:ok, _} = Game.add_participant(game_id, user1)
      {:ok, _} = Game.add_participant(game_id, user2)

      {:ok, game} = Game.remove_participant(game_id, user1.uuid)

      assert length(game.participants) == 1
      assert hd(game.participants).uuid == user2.uuid
      assert game.scores[user1.uuid] == nil
      assert game.scores[user2.uuid] == 0
    end

    test "returns error when user not found", %{game_id: game_id} do
      assert {:error, :user_not_found} = Game.remove_participant(game_id, "nonexistent")
    end
  end

  describe ":waiting state - start_game" do
    test "transitions to :in_progress when valid", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      {:ok, _} = Game.add_participant(game_id, user1)
      {:ok, _} = Game.add_participant(game_id, user2)

      {:ok, game} = Game.start_game(game_id)

      assert game.status == :in_progress

      # Verify queue has participants
      {:ok, response} = Game.get_state(game_id)
      assert response.turn != nil
      assert length(response.queue) == 2
    end

    test "rejects start with insufficient participants", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      {:ok, _} = Game.add_participant(game_id, user1)

      assert {:error, :insufficient_participants} = Game.start_game(game_id)
    end

    test "rejects start with no participants", %{game_id: game_id} do
      assert {:error, :insufficient_participants} = Game.start_game(game_id)
    end
  end

  describe ":waiting state - invalid actions" do
    test "rejects next_phase in waiting", %{game_id: game_id} do
      assert {:error, :invalid_action} = Game.next_phase(game_id)
    end

    test "rejects increment_score in waiting", %{game_id: game_id} do
      assert {:error, :invalid_action} = Game.increment_score(game_id, "user-1")
    end
  end

  describe ":in_progress state - operations" do
    setup %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      {:ok, _} = Game.add_participant(game_id, user1)
      {:ok, _} = Game.add_participant(game_id, user2)
      {:ok, _} = Game.start_game(game_id)

      %{user1: user1, user2: user2}
    end

    test "can remove participant during game", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.remove_participant(game_id, user1.uuid)

      assert length(game.participants) == 1
      assert game.scores[user1.uuid] == nil
    end

    test "can advance turn phase", %{game_id: game_id} do
      # Turn FSM starts in :waiting, needs players to advance
      assert {:ok, _} = Game.next_phase(game_id)
    end

    test "can increment score", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.increment_score(game_id, user1.uuid, 1)

      assert game.scores[user1.uuid] == 1
      assert game.status == :in_progress
    end

    test "transitions to :finished when max_score reached", %{game_id: game_id, user1: user1} do
      # Increment score to max (default is 10)
      {:ok, game} = Game.increment_score(game_id, user1.uuid, 9)
      assert game.status == :in_progress

      # Increment to reach max_score
      {:ok, game} = Game.increment_score(game_id, user1.uuid, 1)
      assert game.status == :finished
      assert game.scores[user1.uuid] == 10
    end
  end

  describe ":in_progress state - invalid actions" do
    setup %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      {:ok, _} = Game.add_participant(game_id, user1)
      {:ok, _} = Game.add_participant(game_id, user2)
      {:ok, _} = Game.start_game(game_id)

      :ok
    end

    test "rejects add_participant during game", %{game_id: game_id} do
      new_user = %User{uuid: "new-user", name: "NewUser"}
      assert {:error, :invalid_action} = Game.add_participant(game_id, new_user)
    end

    test "rejects start_game when already in progress", %{game_id: game_id} do
      assert {:error, :game_already_started} = Game.start_game(game_id)
    end
  end

  describe ":finished state" do
    setup %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      {:ok, _} = Game.add_participant(game_id, user1)
      {:ok, _} = Game.add_participant(game_id, user2)
      {:ok, _} = Game.start_game(game_id)
      {:ok, _} = Game.increment_score(game_id, user1.uuid, 10)

      :ok
    end

    test "can get_state in finished", %{game_id: game_id} do
      {:ok, game} = Game.get_state(game_id)
      assert game.status == :finished
    end

    test "rejects all mutations in finished state", %{game_id: game_id} do
      new_user = %User{uuid: "new", name: "New"}

      assert {:error, :game_finished} = Game.add_participant(game_id, new_user)
      assert {:error, :game_finished} = Game.remove_participant(game_id, "user-1")
      assert {:error, :game_finished} = Game.start_game(game_id)
      assert {:error, :game_finished} = Game.next_phase(game_id)
      assert {:error, :game_finished} = Game.increment_score(game_id, "user-1")
    end
  end

  describe "get_state" do
    test "returns game and turn data", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      {:ok, _} = Game.add_participant(game_id, user1)
      {:ok, _} = Game.add_participant(game_id, user2)
      {:ok, _} = Game.start_game(game_id)

      {:ok, game} = Game.get_state(game_id)

      assert game.status == :in_progress
      assert game.turn != nil
      assert game.turn.phase == :waiting
      assert length(game.queue) == 2
    end

    test "returns nil turn when not started", %{game_id: game_id} do
      {:ok, game} = Game.get_state(game_id)

      assert game.turn == nil
      assert game.status == :waiting
    end
  end
end
