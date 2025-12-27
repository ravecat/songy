defmodule Songy.Boundary.GameTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Game
  alias Songy.Core.Track
  alias Songy.Core.User

  setup %{test: test} do
    Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn :providers, user_id ->
      {:ok,
       %Songy.Core.Provider.Spotify{
         access_token: "token-#{user_id}",
         refresh_token: "refresh-#{user_id}"
       }}
    end)

    Repatch.patch(Songy.Boundary.Player, :search_random_track, [mode: :shared], fn _provider ->
      {:ok,
       %Track{
         id: "track-1",
         title: "Random Song",
         artist: "Random Artist",
         year: 2023,
         meta: %{uri: "spotify:track:track-1"}
       }}
    end)

    owner = %User{uuid: "owner-1", name: "Owner"}
    game_id = to_string(test)

    {:ok, _pid} = start_supervised({Game, id: game_id, owner_id: owner.uuid})
    {:ok, pid} = Game.lookup_game(game_id)
    :ok = Repatch.allow(self(), pid)

    %{game_id: game_id, owner: owner}
  end

  defp join_participant(game_id, user_id) do
    {:ok, pid} = Game.lookup_game(game_id)
    send(pid, {:participant_joined, user_id})
    await_participant(game_id, user_id)
  end

  defp leave_participant(game_id, user_id) do
    {:ok, pid} = Game.lookup_game(game_id)
    send(pid, {:participant_left, user_id})
    await_no_participant(game_id, user_id)
  end

  defp await_participant(game_id, user_id) do
    wait_until(fn ->
      case Game.get_state(game_id) do
        {:ok, game} -> Enum.any?(game.participants, &(&1.uuid == user_id))
        _ -> false
      end
    end)
  end

  defp await_no_participant(game_id, user_id) do
    wait_until(fn ->
      case Game.get_state(game_id) do
        {:ok, game} -> Enum.all?(game.participants, &(&1.uuid != user_id))
        _ -> false
      end
    end)
  end

  defp wait_until(fun, attempts \\ 25) do
    if fun.() do
      :ok
    else
      if attempts <= 0 do
        flunk("condition not met")
      else
        Process.sleep(5)
        wait_until(fun, attempts - 1)
      end
    end
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

  describe ":waiting state - presence join" do
    test "adds participant successfully", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      :ok = join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      assert length(game.participants) == 1
      assert hd(game.participants).uuid == user1.uuid
      assert game.scores[user1.uuid] == 0
      assert game.status == :waiting
    end

    test "initializes timeline for new participant", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      :ok = join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      assert length(Map.get(game.timelines, user1.uuid, [])) == 1
    end

    test "keeps stored timeline on reconnect", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      :ok = join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)
      [track] = Map.get(game.timelines, user1.uuid, [])

      :ok = leave_participant(game_id, user1.uuid)
      :ok = join_participant(game_id, user1.uuid)
      {:ok, rejoined_game} = Game.get_state(game_id)

      assert rejoined_game.timelines[user1.uuid] == [track]
    end

    test "adds multiple participants", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      :ok = join_participant(game_id, user1.uuid)
      :ok = join_participant(game_id, user2.uuid)

      {:ok, game} = Game.get_state(game_id)

      assert length(game.participants) == 2
      assert game.scores[user1.uuid] == 0
      assert game.scores[user2.uuid] == 0
    end

    test "ignores duplicate participants", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      :ok = join_participant(game_id, user1.uuid)
      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_joined, user1.uuid})

      wait_until(fn ->
        {:ok, game} = Game.get_state(game_id)
        length(game.participants) == 1
      end)
    end

    test "ignores when game is full", %{game_id: game_id} do
      users = for i <- 1..10, do: %User{uuid: "user-#{i}", name: "Player#{i}"}

      Enum.each(users, fn user ->
        :ok = join_participant(game_id, user.uuid)
      end)

      extra_user = %User{uuid: "user-11", name: "Player11"}
      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_joined, extra_user.uuid})

      wait_until(fn ->
        {:ok, game} = Game.get_state(game_id)
        length(game.participants) == 10
      end)
    end
  end

  describe ":waiting state - presence leave" do
    test "removes participant successfully", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      :ok = join_participant(game_id, user1.uuid)
      :ok = join_participant(game_id, user2.uuid)

      :ok = leave_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      assert length(game.participants) == 1
      assert hd(game.participants).uuid == user2.uuid
      assert game.scores[user1.uuid] == nil
      assert game.scores[user2.uuid] == 0
    end

    test "ignores unknown participant", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      :ok = join_participant(game_id, user1.uuid)
      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_left, "missing"})

      wait_until(fn ->
        {:ok, game} = Game.get_state(game_id)
        length(game.participants) == 1
      end)
    end
  end

  describe ":waiting state - start_game" do
    test "transitions to :in_progress when valid", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      :ok = join_participant(game_id, user1.uuid)
      :ok = join_participant(game_id, user2.uuid)

      {:ok, game} = Game.start_game(game_id)

      assert game.status == :in_progress

      {:ok, response} = Game.get_state(game_id)
      assert response.turn != nil
      assert length(response.queue) == 2
    end

    test "rejects start with insufficient participants", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      :ok = join_participant(game_id, user1.uuid)

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
  end

  describe ":in_progress state - operations" do
    setup %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      :ok = join_participant(game_id, user1.uuid)
      :ok = join_participant(game_id, user2.uuid)
      {:ok, _} = Game.start_game(game_id)

      %{user1: user1, user2: user2}
    end

    test "can remove participant during game", %{game_id: game_id, user1: user1} do
      :ok = leave_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      assert length(game.participants) == 1
      assert game.scores[user1.uuid] == nil
    end

    test "can advance turn phase", %{game_id: game_id} do
      assert {:ok, _} = Game.next_phase(game_id)
    end

  end

  describe ":in_progress state - invalid actions" do
    setup %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      :ok = join_participant(game_id, user1.uuid)
      :ok = join_participant(game_id, user2.uuid)
      {:ok, _} = Game.start_game(game_id)

      :ok
    end

    test "rejects start_game when already in progress", %{game_id: game_id} do
      assert {:error, :game_already_started} = Game.start_game(game_id)
    end
  end


  describe "get_state" do
    test "returns game and turn data", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      :ok = join_participant(game_id, user1.uuid)
      :ok = join_participant(game_id, user2.uuid)
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

  describe ":challenging" do
    setup %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      :ok = join_participant(game_id, user1.uuid)
      :ok = join_participant(game_id, user2.uuid)
      {:ok, _} = Game.start_game(game_id)

      # Advance to challenging phase
      # waiting -> ready
      {:ok, _} = Game.next_phase(game_id)
      # ready -> steady
      {:ok, _} = Game.next_phase(game_id)

      %{user1: user1, user2: user2}
    end

    test "auto-advances from challenging to results after timeout", %{game_id: game_id} do
      # steady -> challenging
      {:ok, game} = Game.next_phase(game_id)
      assert game.turn.phase == :challenging

      {:ok, game} = Game.get_state(game_id)
      assert game.turn.phase == :results
    end
  end
end
