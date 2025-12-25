defmodule SongyWeb.RoomChannelTest do
  use SongyWeb.ChannelCase

  alias Songy.Boundary.GameSession
  alias Songy.Core.Track
  alias Songy.Core.User

  defp join_room_channel(current_user, room_uuid, assigns \\ %{}) do
    default_assigns = %{current_user_id: current_user.uuid}

    SongyWeb.UserSocket
    |> socket("user_id", Map.merge(default_assigns, assigns))
    |> subscribe_and_join(SongyWeb.RoomChannel, "room:#{room_uuid}")
  end

  setup do
    previous_timeout = Application.fetch_env!(:songy, :challenging_phase_timeout)
    Application.put_env(:songy, :challenging_phase_timeout, :timer.seconds(8))
    on_exit(fn -> Application.put_env(:songy, :challenging_phase_timeout, previous_timeout) end)

    current_user = User.get_user("test-uuid")
    owner = User.get_user("owner123")

    {:ok, game} = GameSession.create_game_session(owner.uuid)

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

  describe "join" do
    test "broadcasts update", %{current_user: current_user, game: game} do
      {:ok, _reply, _socket} = join_room_channel(current_user, game.id)

      assert_broadcast("presence_diff", %{joins: joins})
      assert Map.has_key?(joins, current_user.uuid)

      assert_broadcast("state_updated", %{participants: participants})
      assert Enum.any?(participants, &(&1.uuid == current_user.uuid))
    end
  end

  describe "start_game event" do
    test "changes game status", %{current_user: current_user, owner: owner, game: game} do
      {:ok, _, socket} = join_room_channel(current_user, game.id)
      join_room_channel(owner, game.id)

      push(socket, "start_game", %{})

      assert_broadcast("state_updated", %{status: :in_progress, track: %Track{}})
    end
  end

  describe "next_phase event" do
    test "advances game phase", %{
      current_user: current_user,
      owner: owner,
      game: game
    } do
      {:ok, _, socket} = join_room_channel(current_user, game.id)
      join_room_channel(owner, game.id)

      push(socket, "start_game", %{})
      assert_broadcast("state_updated", %{status: :in_progress})

      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :ready}})
    end
  end

  describe "make_assumption event" do
    test "adds turn track to timeline", %{
      current_user: current_user,
      owner: owner,
      game: game
    } do
      {:ok, _, socket} = join_room_channel(current_user, game.id)
      join_room_channel(owner, game.id)
      # Skip the presence update broadcast
      assert_broadcast("state_updated", _)

      push(socket, "start_game", %{})
      assert_broadcast("state_updated", %{status: :in_progress, track: %Track{}})

      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :ready}, track: %Track{}})

      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :steady}, track: %Track{}})

      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :challenging}, track: track})

      push(socket, "make_assumption", %{"position" => 0})

      assert_broadcast(
        "state_updated",
        %{turn: %{timeline: [^track], assumptions: [%{position: 0, user_id: _}]}}
      )
    end
  end

  describe "reorder_timeline event" do
    test "reorders assumption", %{
      current_user: current_user,
      owner: owner,
      game: game
    } do
      {:ok, _, socket} = join_room_channel(current_user, game.id)
      join_room_channel(owner, game.id)
      # Skip the presence update broadcast
      assert_broadcast("state_updated", _)

      push(socket, "start_game", %{})
      assert_broadcast("state_updated", %{status: :in_progress, track: %Track{}})

      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :ready}, track: %Track{}})

      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :steady}, track: %Track{}})

      push(socket, "next_phase", %{})
      assert_broadcast("state_updated", %{turn: %{phase: :challenging}, track: track})

      push(socket, "make_assumption", %{"position" => 0})

      assert_broadcast(
        "state_updated",
        %{turn: %{timeline: [^track], assumptions: [%{position: 0, user_id: _}]}}
      )

      push(socket, "reorder_timeline", %{"position" => 0})

      assert_broadcast(
        "state_updated",
        %{turn: %{timeline: [^track], assumptions: [%{position: 0, user_id: _}]}}
      )
    end
  end
end
