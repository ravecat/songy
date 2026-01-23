defmodule Songy.PolicyTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Game
  alias Songy.Core.Turn
  alias Songy.Policy

  @owner_cases [
    %{state: :waiting, phase: nil, allowed: [:start_game]},
    %{state: :in_progress, phase: :waiting, allowed: [:advance_turn, :start_turn]},
    %{state: :in_progress, phase: :ready, allowed: [:control_playback]},
    %{state: :in_progress, phase: :challenging, allowed: [:control_playback]},
    %{state: :in_progress, phase: :results, allowed: [:control_playback, :advance_turn, :see_assumptions]},
    %{state: :finished, phase: nil, allowed: [:restart_game]}
  ]

  @player_cases [
    %{state: :waiting, phase: nil, allowed: []},
    %{state: :in_progress, phase: :waiting, allowed: [:advance_turn, :start_turn]},
    %{state: :in_progress, phase: :ready, allowed: [:control_playback, :make_assumption]},
    %{state: :in_progress, phase: :challenging, allowed: []},
    %{state: :in_progress, phase: :results, allowed: [:advance_turn, :control_playback, :see_assumptions]},
    %{state: :finished, phase: nil, allowed: []}
  ]

  @challenger_cases [
    %{state: :waiting, phase: nil, allowed: []},
    %{state: :in_progress, phase: :waiting, allowed: []},
    %{state: :in_progress, phase: :ready, allowed: []},
    %{state: :in_progress, phase: :challenging, allowed: [:control_playback, :make_assumption]},
    %{state: :finished, phase: nil, allowed: []}
  ]

  describe "owner policies" do
    for %{state: state, phase: phase, allowed: allowed} <- @owner_cases do
      for action <- allowed do
        test "allow #{action} in #{state} #{phase}" do
          game = game(unquote(state), unquote(phase), "owner", ["player", "owner"])
          assert :ok == Bodyguard.permit(Policy, unquote(action), "owner", game)
        end
      end

      for action <- Policy.acts() -- allowed do
        test "deny #{action} in #{state} #{phase}" do
          game = game(unquote(state), unquote(phase), "owner", ["player", "owner"])
          assert {:error, :unauthorized} == Bodyguard.permit(Policy, unquote(action), "owner", game)
        end
      end
    end
  end

  describe "player policies" do
    for %{state: state, phase: phase, allowed: allowed} <- @player_cases do
      for action <- allowed do
        test "allow #{action} in #{state} #{phase}" do
          game = game(unquote(state), unquote(phase), "owner", ["player", "challenger"])
          assert :ok == Bodyguard.permit(Policy, unquote(action), "player", game)
        end
      end

      for action <- Policy.acts() -- allowed do
        test "deny #{action} in #{state} #{phase}" do
          game = game(unquote(state), unquote(phase), "owner", ["player", "challenger"])
          assert {:error, :unauthorized} == Bodyguard.permit(Policy, unquote(action), "player", game)
        end
      end
    end
  end

  describe "challenger policies" do
    for %{state: state, phase: phase, allowed: allowed} <- @challenger_cases do
      for action <- allowed do
        test "allow #{action} in #{state} #{phase}" do
          game = game(unquote(state), unquote(phase), "owner", ["player", "challenger"])
          assert :ok == Bodyguard.permit(Policy, unquote(action), "challenger", game)
        end
      end

      for action <- Policy.acts() -- allowed do
        test "deny #{action} in #{state} #{phase}" do
          game = game(unquote(state), unquote(phase), "owner", ["player", "challenger"])
          assert {:error, :unauthorized} == Bodyguard.permit(Policy, unquote(action), "challenger", game)
        end
      end
    end
  end

  describe "advance_turn in :ready phase requires assumption" do
    test "player without assumption cannot advance_turn" do
      game = game(:in_progress, :ready, "owner", ["player"])
      assert {:error, :unauthorized} = Bodyguard.permit(Policy, :advance_turn, "player", game)
    end

    test "player with assumption can advance_turn" do
      game = game(:in_progress, :ready, "owner", ["player"])
      game = %{game | turn: %{game.turn | assumptions: [%{position: 0, user_id: "player"}]}}
      assert :ok = Bodyguard.permit(Policy, :advance_turn, "player", game)
    end

    test "owner without assumption cannot advance_turn when active" do
      game = game(:in_progress, :ready, "owner", ["owner"])
      assert {:error, :unauthorized} = Bodyguard.permit(Policy, :advance_turn, "owner", game)
    end

    test "owner with assumption can advance_turn when active" do
      game = game(:in_progress, :ready, "owner", ["owner"])
      game = %{game | turn: %{game.turn | assumptions: [%{position: 0, user_id: "owner"}]}}
      assert :ok = Bodyguard.permit(Policy, :advance_turn, "owner", game)
    end
  end

  defp game(state, phase, owner_id, queue) do
    %Game{
      status: state,
      owner_id: owner_id,
      queue: queue,
      cursor: 0,
      turn: if(state == :in_progress, do: %Turn{phase: phase, assumptions: []}, else: nil)
    }
  end
end
