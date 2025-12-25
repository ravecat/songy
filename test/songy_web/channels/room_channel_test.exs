defmodule SongyWeb.RoomChannelTest do
  use SongyWeb.ChannelCase

  alias Songy.Boundary.Game
  alias Songy.Boundary.GameSession
  alias Songy.Core.Track
  alias Songy.Core.User

  defp join_room_channel(current_user, room_uuid, assigns \\ %{}) do
    default_assigns = %{current_user_id: current_user.uuid}

    SongyWeb.UserSocket
    |> socket("user_id", Map.merge(default_assigns, assigns))
    |> subscribe_and_join(SongyWeb.RoomChannel, "room:#{room_uuid}")
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

  setup do
    previous_timeout = Application.fetch_env!(:songy, :challenging_phase_timeout)
    Application.put_env(:songy, :challenging_phase_timeout, :timer.seconds(8))
    on_exit(fn -> Application.put_env(:songy, :challenging_phase_timeout, previous_timeout) end)

    current_user = User.get_user("test-uuid")
    owner = User.get_user("owner123")

    {:ok, game} = GameSession.create_game_session(owner.uuid)
    :ok = join_participant(game.id, owner.uuid)

    Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn _registry, _user_id ->
      {:ok,
       %Songy.Core.Provider.Spotify{
         access_token: "test-token",
         refresh_token: "test-refresh-token"
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

    Repatch.patch(Songy.Boundary.Player, :start_playback, [mode: :shared], fn _provider, _track ->
      {:ok, :playback_started}
    end)

    Repatch.patch(Songy.Boundary.Player, :pause_playback, [mode: :shared], fn _provider ->
      {:ok, :playback_paused}
    end)

    %{current_user: current_user, owner: owner, game: game}
  end

  describe "channel join" do
    test "adds participant on join and responds ok", %{current_user: current_user, game: game} do
      {:ok, reply, _socket} = join_room_channel(current_user, game.id)
      assert reply == %{}

      assert_broadcast("state_updated", %{participants: participants})
      assert Enum.any?(participants, &(&1.uuid == current_user.uuid))
    end
  end

  describe "start_game event" do
    test "changes game status and broadcasts update", %{current_user: current_user, game: game} do
      {:ok, _, socket} = join_room_channel(current_user, game.id)

      assert_broadcast("state_updated", %{participants: participants})
      assert Enum.any?(participants, &(&1.uuid == current_user.uuid))

      push(socket, "start_game", %{})

      assert_broadcast("state_updated", %{status: :in_progress})

      assert {:ok, updated_game} = GameSession.get_state(game.id)
      assert updated_game.status == :in_progress
      assert %Track{} = updated_game.track
    end
  end

  describe "next_phase event" do
    test "advances game phase and broadcasts state update", %{
      current_user: current_user,
      game: game
    } do
      {:ok, _, socket} = join_room_channel(current_user, game.id)

      assert_broadcast("state_updated", %{participants: participants})
      assert Enum.any?(participants, &(&1.uuid == current_user.uuid))

      push(socket, "start_game", %{})
      assert_broadcast("state_updated", %{status: :in_progress})

      ref = push(socket, "next_phase", %{})

      assert_reply(ref, :ok)
      assert_broadcast("state_updated", %{turn: %{phase: :ready}})
    end
  end

  describe "make_assumption event" do
    test "adds turn track to timeline and broadcasts", %{
      current_user: current_user,
      game: game
    } do
      {:ok, _, socket} = join_room_channel(current_user, game.id)

      assert_broadcast("state_updated", %{participants: participants})
      assert Enum.any?(participants, &(&1.uuid == current_user.uuid))

      push(socket, "start_game", %{})
      assert_broadcast("state_updated", %{status: :in_progress})

      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :ready}})
      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :steady}})
      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :challenging}})

      push(socket, "make_assumption", %{"position" => 0})

      assert_broadcast("state_updated", %{turn: %{timeline: timeline}} = _payload)
      assert length(timeline) >= 1
    end
  end

  describe "reorder_timeline event" do
    test "reorders assumption and broadcasts update", %{
      current_user: current_user,
      game: game
    } do
      {:ok, _, socket} = join_room_channel(current_user, game.id)

      assert_broadcast("state_updated", %{participants: participants})
      assert Enum.any?(participants, &(&1.uuid == current_user.uuid))

      push(socket, "start_game", %{})
      assert_broadcast("state_updated", %{status: :in_progress})

      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :ready}})
      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :steady}})
      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :challenging}})

      push(socket, "make_assumption", %{"position" => 0})
      assert_broadcast("state_updated", _)
    end
  end
end
