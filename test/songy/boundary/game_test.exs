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

    Repatch.patch(Songy.Boundary.Player, :pause_playback, [mode: :shared], fn _provider ->
      {:ok, :playback_paused}
    end)

    owner = %User{uuid: "owner-1", name: "Owner"}
    game_id = to_string(test)

    {:ok, _pid} = start_supervised({Game, id: game_id, owner_id: owner.uuid})
    {:ok, pid} = Game.lookup_game(game_id)
    :ok = Repatch.allow(self(), pid)
    :ok = Phoenix.PubSub.subscribe(Songy.PubSub, "room:#{game_id}")

    %{game_id: game_id, owner: owner}
  end

  defp join_participant(game_id, user_id) do
    {:ok, pid} = Game.lookup_game(game_id)
    send(pid, {:participant_joined, user_id})
    :ok
  end

  defp leave_participant(game_id, user_id) do
    {:ok, pid} = Game.lookup_game(game_id)
    send(pid, {:participant_left, user_id})
    :ok
  end

  describe ":waiting - :none - initialization" do
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

  describe ":waiting - :none - join participant" do
    test "adds participant successfully", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      assert length(game.participants) == 1
      assert hd(game.participants).uuid == user1.uuid
      assert game.scores[user1.uuid] == 0
      assert game.status == :waiting
    end

    test "initializes timeline for new participant", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      assert length(Map.get(game.timelines, user1.uuid, [])) == 1
    end

    test "keeps stored timeline on reconnect", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)
      assert [track] = Map.get(game.timelines, user1.uuid, [])

      leave_participant(game_id, user1.uuid)
      join_participant(game_id, user1.uuid)
      {:ok, rejoined_game} = Game.get_state(game_id)

      assert [^track] = rejoined_game.timelines[user1.uuid]
    end

    test "adds multiple participants", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      join_participant(game_id, user2.uuid)

      {:ok, game} = Game.get_state(game_id)

      assert length(game.participants) == 2
      assert game.scores[user1.uuid] == 0
      assert game.scores[user2.uuid] == 0
    end

    test "ignores duplicate participants", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      join_participant(game_id, user1.uuid)
      assert_receive {:game_state_updated, _game}
      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_joined, user1.uuid})

      refute_receive {:game_state_updated, _game}
      {:ok, game} = Game.get_state(game_id)
      assert length(game.participants) == 1
    end

    test "ignores when game is full", %{game_id: game_id} do
      users = for i <- 1..10, do: %User{uuid: "user-#{i}", name: "Player#{i}"}

      Enum.each(users, fn user ->
        join_participant(game_id, user.uuid)
        assert_receive {:game_state_updated, _game}
      end)

      extra_user = %User{uuid: "user-11", name: "Player11"}
      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_joined, extra_user.uuid})

      refute_receive {:game_state_updated, _game}
      {:ok, game} = Game.get_state(game_id)
      assert length(game.participants) == 10
    end
  end

  describe ":waiting - :none - leave participant" do
    test "removes participant successfully", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      join_participant(game_id, user2.uuid)

      leave_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      assert length(game.participants) == 1
      assert hd(game.participants).uuid == user2.uuid
      assert game.scores[user1.uuid] == 0
      assert game.scores[user2.uuid] == 0
    end

    test "ignores unknown participant", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      join_participant(game_id, user1.uuid)
      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_left, "missing"})

      assert_receive {:game_state_updated, game}
      assert length(game.participants) == 1
    end
  end

  describe ":waiting - :none - start game" do
    test "transitions to :in_progress when valid", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      join_participant(game_id, user2.uuid)

      {:ok, game} = Game.start_game(game_id)

      assert game.status == :in_progress

      {:ok, response} = Game.get_state(game_id)
      assert response.turn != nil
      assert length(response.queue) == 2
    end

    test "rejects start with insufficient participants", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      join_participant(game_id, user1.uuid)

      assert {:error, :insufficient_participants} = Game.start_game(game_id)
    end

    test "rejects start with no participants", %{game_id: game_id} do
      assert {:error, :insufficient_participants} = Game.start_game(game_id)
    end
  end

  describe ":waiting - :none - advance phase" do
    test "rejects by game", %{game_id: game_id} do
      assert {:error, :invalid_action} = Game.next_phase(game_id)
    end
  end

  describe ":waiting - :none - persistence across disconnects" do
    test "preserves queue position on disconnect/reconnect", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      join_participant(game_id, user2.uuid)

      {:ok, game} = Game.get_state(game_id)
      assert game.queue == [user1.uuid, user2.uuid]

      # User1 disconnects
      leave_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Queue should still contain user1
      assert game.queue == [user1.uuid, user2.uuid]
      assert length(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Queue and participants should be restored
      assert game.queue == [user1.uuid, user2.uuid]
      assert length(game.participants) == 2
    end

    test "restores score on reconnect", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      join_participant(game_id, user2.uuid)

      {:ok, game} = Game.get_state(game_id)
      initial_score = game.scores[user1.uuid]

      # User1 disconnects
      leave_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Score should be preserved even after disconnect
      assert game.scores[user1.uuid] == initial_score
      assert length(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Score should be restored
      assert game.scores[user1.uuid] == initial_score
      assert length(game.participants) == 2
    end

    test "keeps stored timeline on reconnect", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)
      [track] = Map.get(game.timelines, user1.uuid, [])

      leave_participant(game_id, user1.uuid)
      join_participant(game_id, user1.uuid)
      {:ok, rejoined_game} = Game.get_state(game_id)

      assert rejoined_game.timelines[user1.uuid] == [track]
    end
  end

  describe ":waiting - :none - get_state" do
    test "returns nil turn when not started", %{game_id: game_id} do
      {:ok, game} = Game.get_state(game_id)

      assert game.turn == nil
      assert game.status == :waiting
    end
  end

  describe ":in_progress - :waiting - persistence across disconnects" do
    setup %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      join_participant(game_id, user2.uuid)
      {:ok, _} = Game.start_game(game_id)

      {:ok, game} = Game.get_state(game_id)
      assert game.turn.phase == :waiting

      %{user1: user1, user2: user2}
    end

    test "preserves queue position on disconnect/reconnect", %{game_id: game_id, user1: user1, user2: user2} do
      {:ok, game} = Game.get_state(game_id)
      assert game.queue == [user1.uuid, user2.uuid]

      # User1 disconnects
      leave_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Queue should still contain user1
      assert game.queue == [user1.uuid, user2.uuid]
      assert length(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Queue and participants should be restored
      assert game.queue == [user1.uuid, user2.uuid]
      assert length(game.participants) == 2
    end

    test "restores score on reconnect", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.get_state(game_id)
      initial_score = game.scores[user1.uuid]

      # User1 disconnects
      leave_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Score should be preserved even after disconnect
      assert game.scores[user1.uuid] == initial_score
      assert length(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Score should be restored
      assert game.scores[user1.uuid] == initial_score
      assert length(game.participants) == 2
    end

    test "keeps stored timeline on reconnect", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.get_state(game_id)
      assert [track] = Map.get(game.timelines, user1.uuid, [])

      leave_participant(game_id, user1.uuid)
      join_participant(game_id, user1.uuid)
      {:ok, rejoined_game} = Game.get_state(game_id)

      assert [^track] = rejoined_game.timelines[user1.uuid]
    end
  end

  describe ":in_progress - :ready - persistence across disconnects" do
    setup %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      join_participant(game_id, user2.uuid)
      {:ok, _} = Game.start_game(game_id)
      {:ok, _} = Game.next_phase(game_id)

      {:ok, game} = Game.get_state(game_id)
      assert game.turn.phase == :ready

      %{user1: user1, user2: user2}
    end

    test "preserves queue position on disconnect/reconnect", %{game_id: game_id, user1: user1, user2: user2} do
      {:ok, game} = Game.get_state(game_id)
      assert game.queue == [user1.uuid, user2.uuid]

      # User1 disconnects
      leave_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Queue should still contain user1
      assert game.queue == [user1.uuid, user2.uuid]
      assert length(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Queue and participants should be restored
      assert game.queue == [user1.uuid, user2.uuid]
      assert length(game.participants) == 2
    end

    test "restores score on reconnect", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.get_state(game_id)
      initial_score = game.scores[user1.uuid]

      # User1 disconnects
      leave_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Score should be preserved even after disconnect
      assert game.scores[user1.uuid] == initial_score
      assert length(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.uuid)
      {:ok, game} = Game.get_state(game_id)

      # Score should be restored
      assert game.scores[user1.uuid] == initial_score
      assert length(game.participants) == 2
    end

    test "keeps stored timeline on reconnect", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.get_state(game_id)
      assert [track] = Map.get(game.timelines, user1.uuid, [])

      leave_participant(game_id, user1.uuid)
      join_participant(game_id, user1.uuid)
      {:ok, rejoined_game} = Game.get_state(game_id)

      assert [^track] = rejoined_game.timelines[user1.uuid]
    end
  end

  describe ":in_progress - :waiting - operations" do
    setup %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      join_participant(game_id, user2.uuid)
      {:ok, _} = Game.start_game(game_id)

      %{user1: user1, user2: user2}
    end

    test "can advance turn phase", %{game_id: game_id} do
      assert {:ok, _} = Game.next_phase(game_id)
    end
  end

  describe ":in_progress - :waiting - start game" do
    test "rejects when already in progress", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      join_participant(game_id, user2.uuid)
      {:ok, _} = Game.start_game(game_id)

      assert {:error, :game_already_started} = Game.start_game(game_id)
    end
  end

  describe ":in_progress - :waiting - get_state" do
    test "returns game and turn data", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      join_participant(game_id, user2.uuid)
      {:ok, _} = Game.start_game(game_id)

      {:ok, game} = Game.get_state(game_id)

      assert game.status == :in_progress
      assert game.turn != nil
      assert game.turn.phase == :waiting
      assert length(game.queue) == 2
    end
  end

  describe ":* - :* - broadcast game state" do
    test "broadcasts on participant join", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}

      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_joined, user1.uuid})

      assert_receive {:game_state_updated, game}
      assert length(game.participants) == 1
      assert hd(game.participants).uuid == user1.uuid
    end

    test "broadcasts on participant leave", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      assert_receive {:game_state_updated, _game}
      join_participant(game_id, user2.uuid)
      assert_receive {:game_state_updated, _game}

      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_left, user1.uuid})

      assert_receive {:game_state_updated, game}
      assert length(game.participants) == 1
      assert hd(game.participants).uuid == user2.uuid
    end

    test "broadcasts on start_game transition", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      assert_receive {:game_state_updated, _game}
      join_participant(game_id, user2.uuid)
      assert_receive {:game_state_updated, _game}

      {:ok, _} = Game.start_game(game_id)

      assert_receive {:game_state_updated, game}
      assert game.status == :in_progress
      assert game.turn.phase == :waiting
    end

    test "broadcasts on next_phase transitions", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      assert_receive {:game_state_updated, _game}
      join_participant(game_id, user2.uuid)
      assert_receive {:game_state_updated, _game}
      {:ok, _} = Game.start_game(game_id)

      # Drain message from start_game
      assert_receive {:game_state_updated, _}

      # Test transition to ready
      {:ok, _} = Game.next_phase(game_id)
      assert_receive {:game_state_updated, game}
      assert game.turn.phase == :ready
    end

    test "broadcasts on start_playback", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      assert_receive {:game_state_updated, _game}
      join_participant(game_id, user2.uuid)
      assert_receive {:game_state_updated, _game}
      {:ok, _} = Game.start_game(game_id)

      # Drain message from start_game
      assert_receive {:game_state_updated, _}

      {:ok, _} = Game.start_playback(game_id)

      assert_receive {:game_state_updated, game}
      assert game.player.is_playback == true
    end

    test "broadcasts on pause_playback", %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      assert_receive {:game_state_updated, _game}
      join_participant(game_id, user2.uuid)
      assert_receive {:game_state_updated, _game}
      {:ok, _} = Game.start_game(game_id)
      assert_receive {:game_state_updated, _}
      {:ok, _} = Game.start_playback(game_id)

      # Drain message from start_playback
      assert_receive {:game_state_updated, _}

      {:ok, _} = Game.pause_playback(game_id)

      assert_receive {:game_state_updated, game}
      assert game.player.is_playback == false
    end
  end

  describe ":in_progress - :challenging - auto advance" do
    setup %{game_id: game_id} do
      user1 = %User{uuid: "user-1", name: "Player1"}
      user2 = %User{uuid: "user-2", name: "Player2"}

      join_participant(game_id, user1.uuid)
      assert_receive {:game_state_updated, _}
      join_participant(game_id, user2.uuid)
      assert_receive {:game_state_updated, _}
      {:ok, _} = Game.start_game(game_id)
      # waiting phase
      assert_receive {:game_state_updated, _}
      # waiting -> ready
      {:ok, _} = Game.next_phase(game_id)
      # ready phase
      assert_receive {:game_state_updated, _}

      %{user1: user1, user2: user2}
    end

    test "auto-advances to results phase after timeout", %{game_id: game_id} do
      {:ok, _} = Game.next_phase(game_id)
      assert_receive {:game_state_updated, game}
      assert game.turn.phase == :challenging

      assert_receive {:game_state_updated, game}
      assert game.turn.phase == :results
    end
  end
end
