defmodule SongyWeb.RoomChannelTest do
  use SongyWeb.ChannelCase

  alias Songy.Boundary.GameSession
  alias Songy.Core.User
  alias SongyWeb.Presence

  defp join_room_channel(current_user, room_id, assigns \\ %{}) do
    default_assigns = %{current_user_id: current_user.uuid}

    SongyWeb.UserSocket
    |> socket("user_id", Map.merge(default_assigns, assigns))
    |> subscribe_and_join(SongyWeb.RoomChannel, "room:#{room_id}")
  end

  setup do
    current_user = User.get_user("test-uuid")
    owner = User.get_user("owner123")

    %{current_user: current_user, owner: owner}
  end

  # === JOIN EVENT ===

  describe "join" do
    test "tracks user presence on join", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting, participants: [], timelines: %{}}}
      end)

      {:ok, _reply, socket} = join_room_channel(current_user, game_id)

      presence_list = Presence.list(socket)
      assert Map.has_key?(presence_list, current_user.uuid)
    end

    test "pushes state to client on join", %{current_user: current_user} do
      game_id = "game-123"
      game_state = %{status: :waiting, participants: [], timelines: %{}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, game_state}
      end)

      {:ok, _reply, _socket} = join_room_channel(current_user, game_id)

      assert_push("state_updated", ^game_state)
    end

    test "handles missing game session gracefully", %{current_user: current_user} do
      game_id = "invalid-game"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:error, :game_not_found}
      end)

      {:ok, _reply, _socket} = join_room_channel(current_user, game_id)

      refute_push("state_updated", _)
    end
  end

  # === START_GAME EVENT ===

  describe "start_game" do
    test "broadcasts state when start_game succeeds", %{current_user: current_user} do
      game_id = "game-123"
      new_game_state = %{status: :in_progress, turn: %{phase: :waiting}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      Repatch.patch(GameSession, :start_game_session, [mode: :shared], fn ^game_id ->
        {:ok, new_game_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", %{status: :waiting})

      push(socket, "start_game", %{})

      assert_broadcast("state_updated", ^new_game_state)
    end

    test "silently handles start_game errors", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      Repatch.patch(GameSession, :start_game_session, [mode: :shared], fn ^game_id ->
        {:error, :insufficient_participants}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", %{status: :waiting})

      push(socket, "start_game", %{})

      # Should not broadcast state on error
      refute_broadcast("state_updated", %{status: :in_progress})
    end
  end

  # === PLAYBACK EVENTS ===

  describe "start_playback" do
    test "owner can start playback", %{owner: owner} do
      game_id = "game-123"
      owner_id = owner.uuid
      new_state = %{player: %{is_playback: true}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      Repatch.patch(GameSession, :start_playback, [mode: :shared], fn ^game_id, ^owner_id ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(owner, game_id)
      # Consume push from join
      assert_push("state_updated", %{status: :in_progress})

      ref = push(socket, "start_playback", %{})

      assert_reply(ref, :ok)
      assert_broadcast("state_updated", ^new_state)
    end

    test "active player can start playback", %{current_user: current_user} do
      game_id = "game-123"
      active_player_id = current_user.uuid
      new_state = %{player: %{is_playback: true}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      Repatch.patch(GameSession, :start_playback, [mode: :shared], fn ^game_id, ^active_player_id ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", %{status: :in_progress})

      ref = push(socket, "start_playback", %{})

      assert_reply(ref, :ok)
      assert_broadcast("state_updated", ^new_state)
    end

    test "non-owner and non-active player cannot start playback", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      Repatch.patch(GameSession, :start_playback, [mode: :shared], fn ^game_id, ^user_id ->
        {:error, :unauthorized}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", %{status: :in_progress})

      ref = push(socket, "start_playback", %{})

      # Should not get reply on error
      refute_reply(ref, :ok)
      # No broadcast should happen
      refute_broadcast("state_updated", %{player: %{is_playback: true}})
    end

    test "handles start_playback errors silently", %{owner: owner} do
      game_id = "game-123"
      owner_id = owner.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      Repatch.patch(GameSession, :start_playback, [mode: :shared], fn ^game_id, ^owner_id ->
        {:error, :playback_failed}
      end)

      {:ok, _, socket} = join_room_channel(owner, game_id)
      # Consume push from join
      assert_push("state_updated", %{status: :in_progress})

      ref = push(socket, "start_playback", %{})

      # On error, no reply should be sent
      refute_reply(ref, :ok)
      # No broadcast should happen
      refute_broadcast("state_updated", %{player: %{is_playback: true}})
    end
  end

  describe "pause_playback" do
    test "owner can pause playback", %{owner: owner} do
      game_id = "game-123"
      owner_id = owner.uuid
      new_state = %{player: %{is_playback: false}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      Repatch.patch(GameSession, :pause_playback, [mode: :shared], fn ^game_id, ^owner_id ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(owner, game_id)
      # Consume push from join
      assert_push("state_updated", %{status: :in_progress})

      ref = push(socket, "pause_playback", %{})

      assert_reply(ref, :ok)
      assert_broadcast("state_updated", ^new_state)
    end

    test "active player can pause playback", %{current_user: current_user} do
      game_id = "game-123"
      active_player_id = current_user.uuid
      new_state = %{player: %{is_playback: false}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      Repatch.patch(GameSession, :pause_playback, [mode: :shared], fn ^game_id, ^active_player_id ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", %{status: :in_progress})

      ref = push(socket, "pause_playback", %{})

      assert_reply(ref, :ok)
      assert_broadcast("state_updated", ^new_state)
    end

    test "non-owner and non-active player cannot pause playback", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      Repatch.patch(GameSession, :pause_playback, [mode: :shared], fn ^game_id, ^user_id ->
        {:error, :unauthorized}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "pause_playback", %{})

      # Should not get reply on error
      refute_reply(ref, :ok)
      # No broadcast should happen
      refute_broadcast("state_updated", %{player: %{is_playback: false}})
    end

    test "handles pause_playback errors silently", %{owner: owner} do
      game_id = "game-123"
      owner_id = owner.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      Repatch.patch(GameSession, :pause_playback, [mode: :shared], fn ^game_id, ^owner_id ->
        {:error, :pause_failed}
      end)

      {:ok, _, socket} = join_room_channel(owner, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "pause_playback", %{})

      # On error, no reply should be sent
      refute_reply(ref, :ok)
      # No broadcast should happen
      refute_broadcast("state_updated", %{player: %{is_playback: false}})
    end
  end

  # === NEXT_PHASE EVENT ===

  describe "next_phase" do
    test "advances phase when next_phase succeeds", %{current_user: current_user} do
      game_id = "game-123"
      new_state = %{turn: %{phase: :ready}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      Repatch.patch(GameSession, :next_phase, [mode: :shared], fn ^game_id ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "next_phase", %{})

      assert_reply(ref, :ok)
      assert_broadcast("state_updated", ^new_state)
    end

    test "handles next_phase errors silently", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      Repatch.patch(GameSession, :next_phase, [mode: :shared], fn ^game_id ->
        {:error, :game_not_started}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "next_phase", %{})

      # On error, no reply should be sent
      refute_reply(ref, :ok)
      # No broadcast should happen
      refute_broadcast("state_updated", %{turn: %{phase: :ready}})
    end
  end

  # === PROVIDER EVENTS ===

  describe "get_provider" do
    test "returns token when provider found", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn :providers, ^user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: "test-token",
           refresh_token: "test-refresh",
           device_id: nil,
           expires_at: DateTime.utc_now()
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "get_provider", %{})

      assert_reply(ref, :ok, %{token: "test-token"})
    end

    test "returns error when provider not found", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn :providers, ^user_id ->
        {:error, :not_found}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "get_provider", %{})

      assert_reply(ref, :error, %{reason: "invalid_credentials"})
    end

    test "returns error when access token is nil", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn :providers, ^user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: nil,
           refresh_token: "test-refresh",
           device_id: nil,
           expires_at: DateTime.utc_now()
         }}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "get_provider", %{})

      assert_reply(ref, :error, %{reason: "invalid_credentials"})
    end
  end

  describe "update_provider" do
    test "updates provider when successful", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn :providers, ^user_id ->
        {:ok,
         %Songy.Core.Provider.Spotify{
           access_token: "old-token",
           refresh_token: "old-refresh",
           device_id: nil,
           expires_at: DateTime.utc_now()
         }}
      end)

      Repatch.patch(Songy.Providers, :update, [mode: :shared], fn :providers,
                                                                  ^user_id,
                                                                  _updated_provider ->
        :ok
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "update_provider", %{"access_token" => "new-token"})

      assert_reply(ref, :ok)
    end

    test "returns error when provider not found", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      Repatch.patch(Songy.Providers, :lookup, [mode: :shared], fn :providers, ^user_id ->
        {:error, :not_found}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "update_provider", %{"access_token" => "new-token"})

      assert_reply(ref, :error, %{reason: "provider_not_found"})
    end
  end

  describe "get_current_user" do
    test "returns current user data", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "get_current_user", %{})
      assert_reply(ref, :ok, %{uuid: user_uuid})
      assert user_uuid == current_user.uuid
    end
  end

  # === GAME ACTION EVENTS ===

  describe "make_assumption" do
    test "adds assumption when successful", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid
      new_state = %{turn: %{assumptions: [%{position: 0, user_id: user_id}]}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress, turn: %{phase: :challenging}}}
      end)

      Repatch.patch(GameSession, :make_assumption, [mode: :shared], fn ^game_id, ^user_id, 0 ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "make_assumption", %{"position" => 0})

      assert_reply(ref, :ok)
      assert_broadcast("state_updated", ^new_state)
    end

    test "handles make_assumption errors silently", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      Repatch.patch(GameSession, :make_assumption, [mode: :shared], fn ^game_id, ^user_id, 0 ->
        {:error, :not_in_challenging_phase}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "make_assumption", %{"position" => 0})

      # On error, no reply should be sent
      refute_reply(ref, :ok)
      # No broadcast should happen
      refute_broadcast("state_updated", %{turn: %{assumptions: [_ | _]}})
    end

    test "returns error for missing position in payload", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      # Push with empty payload - pattern match fails, goes to generic handle_in
      ref = push(socket, "make_assumption", %{})

      assert_reply(ref, :error)
    end
  end

  describe "reorder_timeline" do
    test "reorders timeline when successful", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid
      new_state = %{turn: %{assumptions: [%{position: 1}]}}

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress, turn: %{phase: :challenging}}}
      end)

      Repatch.patch(GameSession, :reorder_timeline, [mode: :shared], fn ^game_id, ^user_id, 1 ->
        {:ok, new_state}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "reorder_timeline", %{"position" => 1})

      assert_reply(ref, :ok)
      assert_broadcast("state_updated", ^new_state)
    end

    test "handles reorder_timeline errors silently", %{current_user: current_user} do
      game_id = "game-123"
      user_id = current_user.uuid

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      Repatch.patch(GameSession, :reorder_timeline, [mode: :shared], fn ^game_id, ^user_id, 0 ->
        {:error, :user_has_no_assumption}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "reorder_timeline", %{"position" => 0})

      # On error, no reply should be sent
      refute_reply(ref, :ok)
      # No broadcast should happen
      refute_broadcast("state_updated", %{turn: %{assumptions: [%{position: 0}]}})
    end

    test "returns error for missing position in payload", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :in_progress}}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      # Push with empty payload - pattern match fails, goes to generic handle_in
      ref = push(socket, "reorder_timeline", %{})

      assert_reply(ref, :error)
    end
  end

  # === ERROR HANDLING ===

  describe "unknown event" do
    test "returns error for unknown event", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume push from join
      assert_push("state_updated", _)

      ref = push(socket, "unknown_event", %{})
      assert_reply(ref, :error, %{reason: "unknown_event", event: "unknown_event"})
    end

    test "does not broadcast for unknown event", %{current_user: current_user} do
      game_id = "game-123"

      Repatch.patch(GameSession, :get_state, [mode: :shared], fn ^game_id ->
        {:ok, %{status: :waiting}}
      end)

      {:ok, _, socket} = join_room_channel(current_user, game_id)
      # Consume the initial push from join
      assert_push("state_updated", _)

      # Now push unknown event
      push(socket, "unknown_event", %{})

      # Should not broadcast any state change
      refute_broadcast("state_updated", _)
    end
  end
end
