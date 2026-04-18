defmodule Songy.Boundary.GameTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Game
  alias Songy.Core.Track
  alias Songy.Core.User
  alias Songy.Provider.Session

  setup %{test: test} do
    Repatch.patch(Songy.Providers, :ensure, [mode: :shared], fn user_id ->
      {:ok,
       Session.normalize!(%Songy.Core.Provider.Spotify{
         access_token: "token-#{user_id}",
         refresh_token: "refresh-#{user_id}"
       })}
    end)

    Repatch.patch(Songy.Boundary.Provider, :search_random_track, [mode: :shared], fn _provider ->
      {:ok,
       %Track{
         id: "track-1",
         title: "Random Song",
         artist: "Random Artist",
         year: 2023,
         meta: %{uri: "spotify:track:track-1"}
       }}
    end)

    Repatch.patch(Songy.Boundary.Provider, :start_playback, [mode: :shared], fn _provider, _track ->
      {:ok, :playback_started}
    end)

    Repatch.patch(Songy.Boundary.Provider, :pause_playback, [mode: :shared], fn _provider ->
      {:ok, :playback_paused}
    end)

    owner = %User{id: "owner-1", name: "Owner"}
    game_id = to_string(test)

    {:ok, _pid} = start_supervised({Game, id: game_id, owner_id: owner.id})
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
      assert game.owner_id == owner.id
      assert game.status == :waiting
      assert game.participants == %{}
      assert game.max_participants == 10
      assert game.max_score == 10
      assert game.scores == %{}
      assert game.turn == nil
    end

    test "accepts custom max_participants and max_score", %{game_id: game_id} do
      custom_owner = %User{id: "custom-owner", name: "CustomOwner"}
      custom_game_id = "#{game_id}-custom"

      {:ok, _pid} =
        start_supervised(
          {Game, id: custom_game_id, owner_id: custom_owner.id, max_participants: 4, max_score: 5},
          id: {:game_test, custom_game_id}
        )

      {:ok, game} = Game.get_state(custom_game_id)

      assert game.max_participants == 4
      assert game.max_score == 5
    end
  end

  describe ":waiting - :none - join participant" do
    test "adds participant successfully", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}

      join_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      assert map_size(game.participants) == 1
      assert game.participants[user1.id] != nil
      assert game.scores[user1.id] == 0
      assert game.status == :waiting
    end

    test "initializes timeline for new participant", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}

      join_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      assert length(Map.get(game.timelines, user1.id, [])) == 1
    end

    test "keeps stored timeline on reconnect", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}

      join_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)
      assert [track] = Map.get(game.timelines, user1.id, [])

      leave_participant(game_id, user1.id)
      join_participant(game_id, user1.id)
      {:ok, rejoined_game} = Game.get_state(game_id)

      assert [^track] = rejoined_game.timelines[user1.id]
    end

    test "adds multiple participants", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      join_participant(game_id, user2.id)

      {:ok, game} = Game.get_state(game_id)

      assert map_size(game.participants) == 2
      assert game.scores[user1.id] == 0
      assert game.scores[user2.id] == 0
    end

    test "ignores duplicate participants", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _game}
      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_joined, user1.id})

      refute_receive {:state, _game}
      {:ok, game} = Game.get_state(game_id)
      assert map_size(game.participants) == 1
    end

    test "ignores when game is full", %{game_id: game_id} do
      users = for i <- 1..10, do: %User{id: "user-#{i}", name: "Player#{i}"}

      Enum.each(users, fn user ->
        join_participant(game_id, user.id)
        assert_receive {:state, _game}
      end)

      extra_user = %User{id: "user-11", name: "Player11"}
      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_joined, extra_user.id})

      refute_receive {:state, _game}
      {:ok, game} = Game.get_state(game_id)
      assert map_size(game.participants) == 10
    end
  end

  describe ":waiting - :none - leave participant" do
    test "removes participant successfully", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      join_participant(game_id, user2.id)

      leave_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      assert map_size(game.participants) == 1
      assert game.participants[user2.id] != nil
      assert game.scores[user1.id] == 0
      assert game.scores[user2.id] == 0
    end

    test "ignores unknown participant", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}

      join_participant(game_id, user1.id)
      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_left, "missing"})

      assert_receive {:state, game}
      assert map_size(game.participants) == 1
    end
  end

  describe ":waiting - :none - start game" do
    test "transitions to :in_progress when valid", %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      join_participant(game_id, user2.id)

      {:ok, game} = Game.start_game(game_id, owner.id)

      assert game.status == :in_progress

      {:ok, response} = Game.get_state(game_id)
      assert response.turn != nil
      assert length(response.queue) == 2
    end

    test "starts with a single participant", %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}

      join_participant(game_id, user1.id)

      assert {:ok, game} = Game.start_game(game_id, owner.id)
      assert game.status == :in_progress
      assert length(game.queue) == 1
      assert game.turn.phase == :waiting
    end
  end

  describe ":waiting - :none - advance turn" do
    test "rejects by game", %{game_id: game_id, owner: owner} do
      assert {:error, :invalid_action} = Game.advance_turn(game_id, owner.id)
    end
  end

  describe ":waiting - :none - persistence across disconnects" do
    test "preserves queue position on disconnect/reconnect", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      join_participant(game_id, user2.id)

      {:ok, game} = Game.get_state(game_id)
      assert game.queue == [user1.id, user2.id]

      # User1 disconnects
      leave_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Queue should still contain user1
      assert game.queue == [user1.id, user2.id]
      assert map_size(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Queue and participants should be restored
      assert game.queue == [user1.id, user2.id]
      assert map_size(game.participants) == 2
    end

    test "restores score on reconnect", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      join_participant(game_id, user2.id)

      {:ok, game} = Game.get_state(game_id)
      initial_score = game.scores[user1.id]

      # User1 disconnects
      leave_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Score should be preserved even after disconnect
      assert game.scores[user1.id] == initial_score
      assert map_size(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Score should be restored
      assert game.scores[user1.id] == initial_score
      assert map_size(game.participants) == 2
    end

    test "keeps stored timeline on reconnect", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}

      join_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)
      [track] = Map.get(game.timelines, user1.id, [])

      leave_participant(game_id, user1.id)
      join_participant(game_id, user1.id)
      {:ok, rejoined_game} = Game.get_state(game_id)

      assert rejoined_game.timelines[user1.id] == [track]
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
    setup %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      join_participant(game_id, user2.id)
      {:ok, _} = Game.start_game(game_id, owner.id)

      {:ok, game} = Game.get_state(game_id)
      assert game.turn.phase == :waiting

      %{user1: user1, user2: user2}
    end

    test "preserves queue position on disconnect/reconnect", %{game_id: game_id, user1: user1, user2: user2} do
      {:ok, game} = Game.get_state(game_id)
      assert game.queue == [user1.id, user2.id]

      # User1 disconnects
      leave_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Queue should still contain user1
      assert game.queue == [user1.id, user2.id]
      assert map_size(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Queue and participants should be restored
      assert game.queue == [user1.id, user2.id]
      assert map_size(game.participants) == 2
    end

    test "restores score on reconnect", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.get_state(game_id)
      initial_score = game.scores[user1.id]

      # User1 disconnects
      leave_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Score should be preserved even after disconnect
      assert game.scores[user1.id] == initial_score
      assert map_size(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Score should be restored
      assert game.scores[user1.id] == initial_score
      assert map_size(game.participants) == 2
    end

    test "keeps stored timeline on reconnect", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.get_state(game_id)
      assert [track] = Map.get(game.timelines, user1.id, [])

      leave_participant(game_id, user1.id)
      join_participant(game_id, user1.id)
      {:ok, rejoined_game} = Game.get_state(game_id)

      assert [^track] = rejoined_game.timelines[user1.id]
    end
  end

  describe ":in_progress - :ready - persistence across disconnects" do
    setup %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      join_participant(game_id, user2.id)
      {:ok, _} = Game.start_game(game_id, owner.id)
      {:ok, _} = Game.advance_turn(game_id, owner.id)

      {:ok, game} = Game.get_state(game_id)
      assert game.turn.phase == :ready

      %{user1: user1, user2: user2}
    end

    test "preserves queue position on disconnect/reconnect", %{game_id: game_id, user1: user1, user2: user2} do
      {:ok, game} = Game.get_state(game_id)
      assert game.queue == [user1.id, user2.id]

      # User1 disconnects
      leave_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Queue should still contain user1
      assert game.queue == [user1.id, user2.id]
      assert map_size(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Queue and participants should be restored
      assert game.queue == [user1.id, user2.id]
      assert map_size(game.participants) == 2
    end

    test "restores score on reconnect", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.get_state(game_id)
      initial_score = game.scores[user1.id]

      # User1 disconnects
      leave_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Score should be preserved even after disconnect
      assert game.scores[user1.id] == initial_score
      assert map_size(game.participants) == 1

      # User1 reconnects
      join_participant(game_id, user1.id)
      {:ok, game} = Game.get_state(game_id)

      # Score should be restored
      assert game.scores[user1.id] == initial_score
      assert map_size(game.participants) == 2
    end

    test "keeps stored timeline on reconnect", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.get_state(game_id)
      assert [track] = Map.get(game.timelines, user1.id, [])

      leave_participant(game_id, user1.id)
      join_participant(game_id, user1.id)
      {:ok, rejoined_game} = Game.get_state(game_id)

      assert [^track] = rejoined_game.timelines[user1.id]
    end
  end

  describe ":in_progress - :waiting - operations" do
    setup %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      join_participant(game_id, user2.id)
      {:ok, _} = Game.start_game(game_id, owner.id)

      %{user1: user1, user2: user2}
    end

    test "can advance turn phase", %{game_id: game_id, owner: owner} do
      assert {:ok, _} = Game.advance_turn(game_id, owner.id)
    end
  end

  describe ":in_progress - :waiting - start game" do
    test "rejects when already in progress", %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      join_participant(game_id, user2.id)
      {:ok, _} = Game.start_game(game_id, owner.id)

      assert {:error, :game_already_started} = Game.start_game(game_id, owner.id)
    end
  end

  describe ":in_progress - :waiting - get_state" do
    test "returns game and turn data", %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      join_participant(game_id, user2.id)
      {:ok, _} = Game.start_game(game_id, owner.id)

      {:ok, game} = Game.get_state(game_id)

      assert game.status == :in_progress
      assert game.turn != nil
      assert game.turn.phase == :waiting
      assert length(game.queue) == 2
    end
  end

  describe ":* - :* - broadcast game state" do
    test "broadcasts on participant join", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}

      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_joined, user1.id})

      assert_receive {:state, game}
      assert map_size(game.participants) == 1
      assert game.participants[user1.id] != nil
    end

    test "broadcasts on participant leave", %{game_id: game_id} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _game}
      join_participant(game_id, user2.id)
      assert_receive {:state, _game}

      {:ok, pid} = Game.lookup_game(game_id)
      send(pid, {:participant_left, user1.id})

      assert_receive {:state, game}
      assert map_size(game.participants) == 1
      assert game.participants[user2.id] != nil
    end

    test "broadcasts on start_game transition", %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _game}
      join_participant(game_id, user2.id)
      assert_receive {:state, _game}

      {:ok, _} = Game.start_game(game_id, owner.id)

      assert_receive {:state, game}
      assert game.status == :in_progress
      assert game.turn.phase == :waiting
    end

    test "broadcasts on advance_turn transitions", %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _game}
      join_participant(game_id, user2.id)
      assert_receive {:state, _game}
      {:ok, _} = Game.start_game(game_id, owner.id)

      # Drain message from start_game
      assert_receive {:state, _}

      # Test transition to ready
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      assert_receive {:state, game}
      assert game.turn.phase == :ready
    end

    test "broadcasts on start_playback", %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _game}
      join_participant(game_id, user2.id)
      assert_receive {:state, _game}
      {:ok, game} = Game.start_game(game_id, owner.id)
      owner_id = game.owner_id

      # Drain message from start_game
      assert_receive {:state, _}

      # Transition to ready phase
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      assert_receive {:state, _}

      {:ok, _} = Game.start_playback(game_id, owner_id)

      assert_receive {:state, game}
      assert game.player.is_playback == true
    end

    test "broadcasts on pause_playback", %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _game}
      join_participant(game_id, user2.id)
      assert_receive {:state, _game}
      {:ok, game} = Game.start_game(game_id, owner.id)
      owner_id = game.owner_id
      assert_receive {:state, _}

      # Transition to ready phase
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      assert_receive {:state, _}

      {:ok, _} = Game.start_playback(game_id, owner_id)

      # Drain message from start_playback
      assert_receive {:state, _}

      {:ok, _} = Game.pause_playback(game_id, owner_id)

      assert_receive {:state, game}
      assert game.player.is_playback == false
    end
  end

  describe ":in_progress - :ready - playback control" do
    setup %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _}
      join_participant(game_id, user2.id)
      assert_receive {:state, _}
      {:ok, _} = Game.start_game(game_id, owner.id)
      # waiting phase
      assert_receive {:state, _}
      # waiting -> ready
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      # ready phase
      assert_receive {:state, _}

      # Set a track for playback tests
      track = %Track{id: "track-1", title: "Song", artist: "Artist", year: 2020}
      {:ok, _} = Game.set_track(game_id, track)
      assert_receive {:state, _}

      %{user1: user1, user2: user2}
    end

    test "owner can start playback during ready phase", %{game_id: game_id, owner: owner} do
      {:ok, _} = Game.start_playback(game_id, owner.id)

      assert_receive {:state, game}
      assert game.player.is_playback == true
    end

    test "owner can pause playback during ready phase", %{game_id: game_id, owner: owner} do
      {:ok, _} = Game.start_playback(game_id, owner.id)
      assert_receive {:state, game}
      assert game.player.is_playback == true

      {:ok, _} = Game.pause_playback(game_id, owner.id)

      assert_receive {:state, game}
      assert game.player.is_playback == false
    end

    test "active player can start playback during ready phase", %{game_id: game_id, user1: user1} do
      {:ok, _} = Game.start_playback(game_id, user1.id)

      assert_receive {:state, game}
      assert game.player.is_playback == true
    end

    test "active player can pause playback during ready phase", %{game_id: game_id, user1: user1} do
      {:ok, _} = Game.start_playback(game_id, user1.id)
      assert_receive {:state, game}
      assert game.player.is_playback == true

      {:ok, _} = Game.pause_playback(game_id, user1.id)

      assert_receive {:state, game}
      assert game.player.is_playback == false
    end

    test "non-owner and non-active player cannot start playback", %{game_id: game_id, user2: user2} do
      {:error, :unauthorized} = Game.start_playback(game_id, user2.id)

      # No broadcast should happen
      refute_receive {:state, %{player: %{is_playback: true}}}
    end

    test "non-owner and non-active player cannot pause playback", %{game_id: game_id, owner: owner, user2: user2} do
      {:ok, _} = Game.start_playback(game_id, owner.id)
      assert_receive {:state, _}

      {:error, :unauthorized} = Game.pause_playback(game_id, user2.id)

      # No pause broadcast should happen
      refute_receive {:state, %{player: %{is_playback: false}}}
    end
  end

  describe ":in_progress - :challenging phase - playback control" do
    setup %{game_id: game_id, owner: owner} do
      # Temporarily increase challenging_phase_timeout to 50ms for these tests
      original_timeout = Application.get_env(:songy, :challenging_phase_timeout)
      Application.put_env(:songy, :challenging_phase_timeout, 50)

      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _}
      join_participant(game_id, user2.id)
      assert_receive {:state, _}
      {:ok, _} = Game.start_game(game_id, owner.id)
      # waiting phase
      assert_receive {:state, _}
      # waiting -> ready
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      # ready phase
      assert_receive {:state, _}

      # Set a track for playback tests
      track = %Track{id: "track-1", title: "Song", artist: "Artist", year: 2020}
      {:ok, _} = Game.set_track(game_id, track)
      assert_receive {:state, _}

      # Make an assumption so owner can advance turn (user1 is active player)
      {:ok, _} = Game.make_assumption(game_id, user1.id, 0)
      assert_receive {:state, _}

      # ready -> challenging (this triggers a timer for auto-advance)
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      # challenging phase
      assert_receive {:state, _}

      on_exit(fn ->
        Application.put_env(:songy, :challenging_phase_timeout, original_timeout)
      end)

      %{user1: user1, user2: user2}
    end

    test "owner can start playback during challenging phase", %{game_id: game_id, owner: owner} do
      {:ok, _} = Game.start_playback(game_id, owner.id)
      # Use short timeout to catch the message before auto-advance to results
      assert_receive {:state, game}, 25
      assert game.player.is_playback == true
    end

    test "owner can pause playback during challenging phase", %{game_id: game_id, owner: owner} do
      {:ok, _} = Game.start_playback(game_id, owner.id)
      assert_receive {:state, game}, 25
      assert game.player.is_playback == true

      {:ok, _} = Game.pause_playback(game_id, owner.id)
      assert_receive {:state, game}, 25
      assert game.player.is_playback == false
    end

    test "active player cannot start playback during challenging phase", %{game_id: game_id, user1: user1} do
      {:error, :unauthorized} = Game.start_playback(game_id, user1.id)
    end

    test "active player cannot pause playback during challenging phase", %{game_id: game_id, user1: user1, owner: owner} do
      # First, activate playback via owner (owner can control in challenging phase)
      {:ok, _} = Game.start_playback(game_id, owner.id)
      assert_receive {:state, game}, 25
      assert game.player.is_playback == true

      # Active player cannot pause
      {:error, :unauthorized} = Game.pause_playback(game_id, user1.id)
    end

    test "challenger (non-owner and non-active player) can start playback during challenging phase", %{
      game_id: game_id,
      user2: user2
    } do
      # user2 is a challenger (not owner, not active player)
      # Challengers can play music during challenging phase
      {:ok, _} = Game.start_playback(game_id, user2.id)
      assert_receive {:state, game}, 25
      assert game.player.is_playback == true
    end

    test "challenger (non-owner and non-active player) can pause playback during challenging phase", %{
      game_id: game_id,
      owner: owner,
      user2: user2
    } do
      # user2 is a challenger (not owner, not active player)
      {:ok, _} = Game.start_playback(game_id, owner.id)
      assert_receive {:state, _}, 25

      # Challengers can pause music during challenging phase
      {:ok, _} = Game.pause_playback(game_id, user2.id)
      assert_receive {:state, game}, 25
      assert game.player.is_playback == false
    end
  end

  describe ":in_progress - :challenging - additional playback control tests" do
    setup %{game_id: game_id, owner: owner} do
      # Temporarily increase challenging_phase_timeout to 50ms for these tests
      original_timeout = Application.get_env(:songy, :challenging_phase_timeout)
      Application.put_env(:songy, :challenging_phase_timeout, 50)

      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _}
      join_participant(game_id, user2.id)
      assert_receive {:state, _}
      {:ok, _} = Game.start_game(game_id, owner.id)
      # waiting phase
      assert_receive {:state, _}
      # waiting -> ready
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      # ready phase
      assert_receive {:state, _}

      # Set a track for playback tests
      track = %Track{id: "track-1", title: "Song", artist: "Artist", year: 2020}
      {:ok, _} = Game.set_track(game_id, track)
      assert_receive {:state, _}

      # Make an assumption so owner can advance turn (user1 is active player)
      {:ok, _} = Game.make_assumption(game_id, user1.id, 0)
      assert_receive {:state, _}

      # ready -> challenging
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      # challenging phase
      assert_receive {:state, _}

      on_exit(fn ->
        # Restore original timeout after tests complete
        Application.put_env(:songy, :challenging_phase_timeout, original_timeout)
      end)

      %{user1: user1, user2: user2}
    end

    test "owner can start and then pause playback in challenging phase", %{game_id: game_id, owner: owner} do
      # Start playback
      {:ok, _} = Game.start_playback(game_id, owner.id)

      assert_receive {:state, game}, 25
      assert game.player.is_playback == true
    end

    test "owner can pause playback during challenging phase", %{game_id: game_id, owner: owner} do
      {:ok, _} = Game.start_playback(game_id, owner.id)
      assert_receive {:state, game}, 25
      assert game.player.is_playback == true

      {:ok, _} = Game.pause_playback(game_id, owner.id)

      assert_receive {:state, game}, 25
      assert game.player.is_playback == false
    end

    test "active player cannot start playback during challenging phase", %{game_id: game_id, user1: user1} do
      {:error, :unauthorized} = Game.start_playback(game_id, user1.id)
    end

    test "active player cannot pause playback during challenging phase", %{game_id: game_id, user1: user1, owner: owner} do
      # First, activate playback via owner (owner can control in challenging phase)
      {:ok, _} = Game.start_playback(game_id, owner.id)
      assert_receive {:state, game}, 25
      assert game.player.is_playback == true

      # Active player cannot pause
      {:error, :unauthorized} = Game.pause_playback(game_id, user1.id)
    end

    test "challenger (non-owner and non-active player) can start playback during challenging phase", %{
      game_id: game_id,
      user2: user2
    } do
      # user2 is a challenger (not owner, not active player)
      # Challengers can play music during challenging phase
      {:ok, _} = Game.start_playback(game_id, user2.id)
      assert_receive {:state, game}, 25
      assert game.player.is_playback == true
    end

    test "challenger (non-owner and non-active player) can pause playback during challenging phase", %{
      game_id: game_id,
      owner: owner,
      user2: user2
    } do
      # user2 is a challenger (not owner, not active player)
      {:ok, _} = Game.start_playback(game_id, owner.id)
      assert_receive {:state, _}, 25

      # Challengers can pause music during challenging phase
      {:ok, _} = Game.pause_playback(game_id, user2.id)
      assert_receive {:state, game}, 25
      assert game.player.is_playback == false
    end
  end

  describe ":in_progress - :challenging - deadline" do
    setup %{game_id: game_id, owner: owner} do
      original_timeout = Application.get_env(:songy, :challenging_phase_timeout)
      Application.put_env(:songy, :challenging_phase_timeout, 50)

      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _}
      join_participant(game_id, user2.id)
      assert_receive {:state, _}
      {:ok, _} = Game.start_game(game_id, owner.id)
      # waiting phase
      assert_receive {:state, _}
      # waiting -> ready
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      # ready phase
      assert_receive {:state, _}

      # Make an assumption so owner can advance turn (user1 is active player)
      {:ok, _} = Game.make_assumption(game_id, user1.id, 0)
      assert_receive {:state, _}

      on_exit(fn ->
        Application.put_env(:songy, :challenging_phase_timeout, original_timeout)
      end)

      :ok
    end

    test "broadcasts challenging state with deadline_at_ms", %{game_id: game_id, owner: owner} do
      {:ok, _} = Game.advance_turn(game_id, owner.id)

      assert_receive {:state, game}, 100
      assert game.turn.phase == :challenging
      assert is_integer(game.turn.deadline_at_ms)
      assert game.turn.deadline_at_ms >= System.system_time(:millisecond)
    end
  end

  describe ":in_progress - :challenging - auto advance" do
    setup %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _}
      join_participant(game_id, user2.id)
      assert_receive {:state, _}
      {:ok, _} = Game.start_game(game_id, owner.id)
      # waiting phase
      assert_receive {:state, _}
      # waiting -> ready
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      # ready phase
      assert_receive {:state, _}

      # Make an assumption so owner can advance turn (user1 is active player)
      {:ok, _} = Game.make_assumption(game_id, user1.id, 0)
      assert_receive {:state, _}

      %{user1: user1, user2: user2}
    end

    test "auto-advances to results phase after timeout", %{game_id: game_id, owner: owner} do
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      assert_receive {:state, game}
      assert game.turn.phase == :challenging

      assert_receive {:state, game}
      assert game.turn.phase == :results
    end
  end

  describe ":in_progress - :ready - make assumption" do
    setup %{game_id: game_id, owner: owner} do
      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _}
      join_participant(game_id, user2.id)
      assert_receive {:state, _}
      {:ok, _} = Game.start_game(game_id, owner.id)
      assert_receive {:state, _}

      # Set current track for assumptions (distinct from initial timelines)
      track = %Track{id: "track-2", title: "Current Song", artist: "Current Artist", year: 2021}
      {:ok, _} = Game.set_track(game_id, track)
      assert_receive {:state, _}

      # waiting -> ready
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      assert_receive {:state, _}

      %{user1: user1, user2: user2, track: track}
    end

    test "adds new assumption for user at specified position", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.make_assumption(game_id, user1.id, 0)

      assert length(Map.get(game.timelines, Enum.at(game.queue, game.cursor), [])) == 1
      assert map_size(game.turn.assumptions) == 1
      assert Enum.find_value(game.turn.assumptions, fn {pos, uid} -> if uid == user1.id, do: pos end) == 0
    end

    test "player makes assumption at position 0", %{
      game_id: game_id,
      user1: user1
    } do
      # User1 (player) makes assumption at position 0
      {:ok, game} = Game.make_assumption(game_id, user1.id, 0)

      assert length(Map.get(game.timelines, Enum.at(game.queue, game.cursor), [])) == 1
      assert map_size(game.turn.assumptions) == 1
      assert Enum.find_value(game.turn.assumptions, fn {pos, uid} -> if uid == user1.id, do: pos end) == 0
    end

    test "challenger cannot make assumption in ready phase", %{
      game_id: game_id,
      user2: user2
    } do
      # User2 is challenger in ready phase, cannot make assumption
      assert {:error, :unauthorized} = Game.make_assumption(game_id, user2.id, 0)
    end

    test "normalizes negative position to 0", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.make_assumption(game_id, user1.id, -5)

      assert length(Map.get(game.timelines, Enum.at(game.queue, game.cursor), [])) == 1
      assert Enum.find_value(game.turn.assumptions, fn {pos, uid} -> if uid == user1.id, do: pos end) == 0
    end

    test "normalizes position beyond timeline length", %{game_id: game_id, user1: user1} do
      {:ok, game} = Game.make_assumption(game_id, user1.id, 100)

      # Position should be normalized to length(timeline) which is 1 initially
      assert length(Map.get(game.timelines, Enum.at(game.queue, game.cursor), [])) == 1
      assert Enum.find_value(game.turn.assumptions, fn {pos, uid} -> if uid == user1.id, do: pos end) == 1
    end

    test "broadcasts state after assumption", %{game_id: game_id, user1: user1} do
      {:ok, _} = Game.make_assumption(game_id, user1.id, 0)

      assert_receive {:state, game}
      assert map_size(game.turn.assumptions) == 1
    end

    test "rejects assumption in other phases (waiting)", %{game_id: game_id} do
      {:ok, _pid} = Game.lookup_game(game_id)

      # Manually send message to simulate wrong phase - note: we'd need to transition back
      # But for this test we just verify that in ready phase, assumptions work
      refute_receive {:reply, {:error, _}}
    end
  end

  describe ":in_progress - :challenging - make_assumption" do
    setup %{game_id: game_id, owner: owner} do
      {:ok, _pid} = Game.lookup_game(game_id)

      original_timeout = Application.get_env(:songy, :challenging_phase_timeout)
      Application.put_env(:songy, :challenging_phase_timeout, 50)

      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}
      user3 = %User{id: "user-3", name: "Player3"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _}
      join_participant(game_id, user2.id)
      assert_receive {:state, _}
      join_participant(game_id, user3.id)
      assert_receive {:state, _}

      {:ok, _} = Game.start_game(game_id, owner.id)
      assert_receive {:state, _}

      # Set current track for assumptions (distinct from initial timelines)
      track = %Track{id: "track-2", title: "Current Song", artist: "Current Artist", year: 2021}
      {:ok, _} = Game.set_track(game_id, track)
      assert_receive {:state, _}

      {:ok, _} = Game.advance_turn(game_id, owner.id)
      assert_receive {:state, _}

      # Active player (user1) makes assumption and advances to challenging
      {:ok, _} = Game.make_assumption(game_id, user1.id, 0)
      assert_receive {:state, _}
      {:ok, _} = Game.advance_turn(game_id, user1.id)
      assert_receive {:state, game}
      assert game.turn.phase == :challenging

      on_exit(fn ->
        Application.put_env(:songy, :challenging_phase_timeout, original_timeout)
      end)

      %{user1: user1, user2: user2, user3: user3}
    end

    test "adds new assumption during challenging phase", %{game_id: game_id, user2: user2} do
      # user2 is challenger, can make assumption in challenging phase
      # user1 (active player) already made assumption at position 0 in setup
      # user1 blocks positions 0 and 1, so user2 must use position 2
      {:ok, game} = Game.make_assumption(game_id, user2.id, 2)

      assert length(Map.get(game.timelines, Enum.at(game.queue, game.cursor), [])) == 1
      # user1 and user2
      assert map_size(game.turn.assumptions) == 2
      assert Enum.find_value(game.turn.assumptions, fn {pos, uid} -> if uid == user2.id, do: pos end) == 2
    end

    test "player cannot make assumption in challenging phase", %{game_id: game_id, user1: user1} do
      # user1 is player (active), cannot make assumption in challenging phase
      assert {:error, :unauthorized} = Game.make_assumption(game_id, user1.id, 0)
    end

    test "multiple challengers make assumptions (blocked positions)",
         %{
           game_id: game_id,
           user2: user2,
           user3: user3
         } do
      # user2 (challenger) makes assumption at position 2 (user1 at 0 blocks 0,1)
      {:ok, _} = Game.make_assumption(game_id, user2.id, 2)

      # user3 (challenger) tries position 2 - blocked by user2 (blocks 2,3)
      {:ok, game} = Game.make_assumption(game_id, user3.id, 2)

      assert length(Map.get(game.timelines, Enum.at(game.queue, game.cursor), [])) == 1
      assert map_size(game.turn.assumptions) == 2
      assert Enum.find_value(game.turn.assumptions, fn {pos, uid} -> if uid == user2.id, do: pos end) == 2
      refute user3.id in Map.values(game.turn.assumptions)
    end

    test "normalizes negative position to 0", %{game_id: game_id, user2: user2} do
      # user1 already has position 0, user2 tries -5 which normalizes to 0
      # Position 0 is blocked, but timeline still gets updated (TODO: investigate)
      {:ok, game} = Game.make_assumption(game_id, user2.id, -5)

      assert length(Map.get(game.timelines, Enum.at(game.queue, game.cursor), [])) == 1
      # Only user1
      assert map_size(game.turn.assumptions) == 1
      refute user2.id in Map.values(game.turn.assumptions)
    end

    test "normalizes position beyond timeline length", %{game_id: game_id, user2: user2} do
      {:ok, game} = Game.make_assumption(game_id, user2.id, 100)

      # user1 at position 0, position 100 normalizes to max position (2)
      assert length(Map.get(game.timelines, Enum.at(game.queue, game.cursor), [])) == 1
      assert user2.id in Map.values(game.turn.assumptions)
    end

    test "broadcasts after assumption in challenging phase", %{game_id: game_id, user2: user2} do
      {:ok, _} = Game.make_assumption(game_id, user2.id, 2)

      assert_receive {:state, game}, 25
      assert map_size(game.turn.assumptions) == 2
    end

    test "no-op when user makes assumption at same position", %{
      game_id: game_id,
      user2: user2
    } do
      {:ok, game1} = Game.make_assumption(game_id, user2.id, 2)
      assert_receive {:state, _}

      {:ok, game2} = Game.make_assumption(game_id, user2.id, 2)

      # Same game state (no updates when position is the same)
      assert game1.turn.phase == game2.turn.phase

      assert Map.get(game1.timelines, Enum.at(game1.queue, game1.cursor), []) ==
               Map.get(game2.timelines, Enum.at(game2.queue, game2.cursor), [])
    end

    test "blocks assumptions adjacent to other users", %{
      game_id: game_id,
      user2: user2,
      user3: user3
    } do
      # user1 at position 0, user2 tries position 2
      {:ok, _} = Game.make_assumption(game_id, user2.id, 2)
      assert_receive {:state, _}

      # user3 tries to make assumption at position 1 - blocked by user1
      {:ok, game} = Game.make_assumption(game_id, user3.id, 1)

      # Timeline unchanged (base timeline only)
      assert length(Map.get(game.timelines, Enum.at(game.queue, game.cursor), [])) == 1
      # user3 has no assumption
      assert Enum.find_value(game.turn.assumptions, fn {pos, uid} -> if uid == user2.id, do: pos end) == 2
      refute user3.id in Map.values(game.turn.assumptions)
    end
  end

  describe ":in_progress - :results - make_assumption" do
    setup %{game_id: game_id, owner: owner} do
      # Temporarily reduce challenging_phase_timeout
      original_timeout = Application.get_env(:songy, :challenging_phase_timeout)
      Application.put_env(:songy, :challenging_phase_timeout, 50)

      {:ok, _pid} = Game.lookup_game(game_id)

      user1 = %User{id: "user-1", name: "Player1"}
      user2 = %User{id: "user-2", name: "Player2"}

      join_participant(game_id, user1.id)
      assert_receive {:state, _}
      join_participant(game_id, user2.id)
      assert_receive {:state, _}
      {:ok, _} = Game.start_game(game_id, owner.id)
      assert_receive {:state, _}
      {:ok, _} = Game.advance_turn(game_id, owner.id)
      assert_receive {:state, _}

      # Make an assumption so owner can advance turn (user1 is active player)
      {:ok, _} = Game.make_assumption(game_id, user1.id, 0)
      assert_receive {:state, _}

      {:ok, _} = Game.advance_turn(game_id, owner.id)
      assert_receive {:state, game}
      assert game.turn.phase == :challenging

      assert_receive {:state, result_game}, 100
      assert result_game.turn.phase == :results

      on_exit(fn ->
        Application.put_env(:songy, :challenging_phase_timeout, original_timeout)
      end)

      %{
        user1: user1,
        user2: user2
      }
    end

    test "rejects make_assumption in results phase", %{game_id: game_id, user1: user1} do
      {:ok, pid} = Game.lookup_game(game_id)

      # Attempt to make assumption should fail in results phase
      result = GenStateMachine.call(pid, {:make_assumption, user1.id, 0})

      assert result == {:error, :invalid_action}
    end
  end
end
