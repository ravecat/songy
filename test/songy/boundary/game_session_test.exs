defmodule Songy.Boundary.GameSessionTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Game
  alias Songy.Boundary.GameSession
  alias Songy.Core.Track
  alias Songy.Core.User

  setup do
    Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn :providers, user_id ->
      {:ok,
       %Songy.Core.Provider.Spotify{
         access_token: "token-#{user_id}",
         refresh_token: "refresh-#{user_id}"
       }}
    end)

    :ok
  end

  defp join_participant(game_id, user_id) do
    {:ok, pid} = Game.lookup_game(game_id)
    send(pid, {:participant_joined, user_id})
    wait_until(fn ->
      case Game.get_state(game_id) do
        {:ok, game} -> Enum.any?(game.participants, &(&1.uuid == user_id))
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

  describe "create_game_session/1" do
    test "starts supervisor and returns initial state" do
      owner = User.get_user("owner-123")

      assert {:ok, game} = GameSession.create_game_session(owner.uuid)

      assert GameSession.game_session_exists?(game.id)

      assert {:ok, pid} = GameSession.lookup_game_session(game.id)
      assert Process.alive?(pid)
    end
  end

  describe "start_game_session/1" do
    setup do
      owner = User.get_user("owner-1")
      {:ok, game} = GameSession.create_game_session(owner.uuid)
      :ok = join_participant(game.id, owner.uuid)
      user = User.get_user("player-1")
      :ok = join_participant(game.id, user.uuid)

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

      %{game_id: game.id, owner: owner, user: user}
    end

    test "fails when not enough participants", %{owner: owner} do
      {:ok, game} = GameSession.create_game_session(owner.uuid)

      assert {:error, :insufficient_participants} = GameSession.start_game_session(game.id)
    end

    test "starts game and sets turn track", %{game_id: game_id} do
      assert {:ok, game} = GameSession.start_game_session(game_id)

      assert game.status == :in_progress
      assert %Track{} = game.track
    end
  end

  describe "playback controls" do
    setup do
      owner = User.get_user("owner-1")
      {:ok, game} = GameSession.create_game_session(owner.uuid)
      :ok = join_participant(game.id, owner.uuid)
      user = User.get_user("player-1")
      :ok = join_participant(game.id, user.uuid)

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

      Repatch.patch(Songy.Boundary.Player, :start_playback, [mode: :shared], fn _provider, _track ->
        {:ok, :playback_started}
      end)

      Repatch.patch(Songy.Boundary.Player, :pause_playback, [mode: :shared], fn _provider ->
        {:ok, :playback_paused}
      end)

      {:ok, game} = GameSession.start_game_session(game.id)

      %{game_id: game.id}
    end

    test "starts playback when game in progress", %{game_id: game_id} do
      assert {:ok, game} = GameSession.start_playback(game_id)
      assert game.player.is_playback == true
    end

    test "pauses playback when already playing", %{game_id: game_id} do
      {:ok, _} = GameSession.start_playback(game_id)
      assert {:ok, game} = GameSession.pause_playback(game_id)
      assert game.player.is_playback == false
    end
  end

  describe "phases and timelines" do
    setup do
      owner = User.get_user("owner-1")
      {:ok, game} = GameSession.create_game_session(owner.uuid)
      :ok = join_participant(game.id, owner.uuid)
      user = User.get_user("player-1")
      :ok = join_participant(game.id, user.uuid)

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

      {:ok, game} = GameSession.start_game_session(game.id)

      %{game_id: game.id, owner: owner}
    end

    test "advances to ready phase", %{game_id: game_id} do
      assert {:ok, game} = GameSession.next_phase(game_id)
      assert game.turn.phase == :ready
    end

    test "assumption updates timeline in a challenging phase", %{game_id: game_id} do
      {:ok, _} = GameSession.next_phase(game_id) # waiting -> ready
      {:ok, _} = GameSession.next_phase(game_id) # ready -> steady
      {:ok, _} = GameSession.next_phase(game_id) # steady -> challenging

      assert {:ok, game} = GameSession.make_assumption(game_id, "player-1", 0)

      assert game.turn.phase == :challenging
      assert length(game.turn.timeline) >= 1
    end
  end
end
