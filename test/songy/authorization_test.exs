defmodule Songy.AuthorizationTest do
  use ExUnit.Case, async: true

  alias Songy.Authorization
  alias Songy.Core.Game
  alias Songy.Core.Turn

  describe "permissions/2 - default" do
    test "returns default permissions when game is nil" do
      permissions = Authorization.permissions(nil, "user-123")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test "returns default permissions when user_id is nil" do
      game = game(:in_progress, :ready, "owner", ["player", "owner"])
      permissions = Authorization.permissions(game, nil)

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end
  end

  describe "permissions/2 - owner" do
    test ":waiting - nil" do
      game = game(:waiting, nil, "owner", ["player", "owner"])
      permissions = Authorization.permissions(game, "owner")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: true,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test ":in_progress - :waiting" do
      game = game(:in_progress, :waiting, "owner", ["player", "owner"])
      permissions = Authorization.permissions(game, "owner")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: true,
               can_start_game: false,
               can_start_turn: true,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test ":in_progress - :ready (not active player)" do
      game = game(:in_progress, :ready, "owner", ["player", "owner"])
      permissions = Authorization.permissions(game, "owner")

      assert permissions == %{
               can_control_playback: true,
               can_advance_turn: true,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test ":in_progress - :ready (active player)" do
      game = game(:in_progress, :ready, "owner", ["owner", "player"])
      permissions = Authorization.permissions(game, "owner")

      assert permissions == %{
               can_control_playback: true,
               can_advance_turn: true,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: true
             }
    end

    test ":in_progress - :challenging" do
      game = game(:in_progress, :challenging, "owner", ["player", "owner"])
      permissions = Authorization.permissions(game, "owner")

      assert permissions == %{
               can_control_playback: true,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test ":in_progress - :results" do
      game = game(:in_progress, :results, "owner", ["player", "owner"])
      permissions = Authorization.permissions(game, "owner")

      assert permissions == %{
               can_control_playback: true,
               can_advance_turn: true,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: true,
               can_make_assumptions: false
             }
    end

    test ":finished - nil" do
      game = game(:finished, nil, "owner", ["player", "owner"])
      permissions = Authorization.permissions(game, "owner")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: true,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end
  end

  describe "permissions/2 - player" do
    test ":waiting - nil" do
      game = game(:waiting, nil, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "player")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test ":in_progress - :waiting" do
      game = game(:in_progress, :waiting, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "player")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: true,
               can_start_game: false,
               can_start_turn: true,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test ":in_progress - :ready" do
      game = game(:in_progress, :ready, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "player")

      assert permissions == %{
               can_control_playback: true,
               can_advance_turn: true,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: true
             }
    end

    test ":in_progress - :challenging" do
      game = game(:in_progress, :challenging, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "player")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test ":in_progress - :results" do
      game = game(:in_progress, :results, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "player")

      assert permissions == %{
               can_control_playback: true,
               can_advance_turn: true,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: true,
               can_make_assumptions: false
             }
    end

    test ":finished - nil" do
      game = game(:finished, nil, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "player")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end
  end

  describe "permissions/2 - challenger" do
    test ":waiting - nil" do
      game = game(:waiting, nil, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "challenger")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test ":in_progress - :waiting" do
      game = game(:in_progress, :waiting, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "challenger")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test ":in_progress - :ready" do
      game = game(:in_progress, :ready, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "challenger")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end

    test ":in_progress - :challenging" do
      game = game(:in_progress, :challenging, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "challenger")

      assert permissions == %{
               can_control_playback: true,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: true
             }
    end

    test ":in_progress - :results" do
      game = game(:in_progress, :results, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "challenger")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: true,
               can_make_assumptions: false
             }
    end

    test ":finished - nil" do
      game = game(:finished, nil, "owner", ["player", "challenger"])
      permissions = Authorization.permissions(game, "challenger")

      assert permissions == %{
               can_control_playback: false,
               can_advance_turn: false,
               can_start_game: false,
               can_start_turn: false,
               can_restart_game: false,
               can_see_assumptions: false,
               can_make_assumptions: false
             }
    end
  end

  defp game(state, phase, owner_id, queue) do
    %Game{
      status: state,
      owner_id: owner_id,
      queue: queue,
      cursor: 0,
      turn: if(state == :in_progress, do: %Turn{phase: phase}, else: nil)
    }
  end
end
