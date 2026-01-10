defmodule Songy.PolicyTest do
  use ExUnit.Case, async: true

  alias Songy.Core.{Game, Turn}

  @all_actions [
    :start_game,
    :start_playback,
    :pause_playback,
    :next_phase,
    :make_assumption,
    :reorder_timeline,
    :spectate
  ]

  @owner_cases [
    %{state: :waiting, phase: nil, allowed: [:start_game]},
    %{state: :in_progress, phase: :waiting, allowed: [:start_playback, :pause_playback, :next_phase]},
    %{state: :in_progress, phase: :ready, allowed: [:start_playback, :pause_playback, :make_assumption, :reorder_timeline]},
    %{
      state: :in_progress,
      phase: :challenging,
      allowed: [:start_playback, :pause_playback, :make_assumption, :reorder_timeline]
    },
    %{state: :in_progress, phase: :results, allowed: [:next_phase]},
    %{state: :finished, phase: nil, allowed: []}
  ]

  @player_cases [
    %{state: :waiting, phase: nil, allowed: []},
    %{state: :in_progress, phase: :waiting, allowed: [:start_playback, :pause_playback, :next_phase]},
    %{state: :in_progress, phase: :ready, allowed: [:start_playback, :pause_playback, :next_phase]},
    %{state: :in_progress, phase: :challenging, allowed: []},
    %{state: :in_progress, phase: :results, allowed: [:next_phase]},
    %{state: :finished, phase: nil, allowed: []}
  ]

  @challenger_cases [
    %{state: :waiting, phase: nil, allowed: []},
    %{state: :in_progress, phase: :waiting, allowed: []},
    %{state: :in_progress, phase: :ready, allowed: []},
    %{state: :in_progress, phase: :challenging, allowed: [:start_playback, :pause_playback]},
    %{state: :finished, phase: nil, allowed: []}
  ]

  describe "owner policies" do
    for %{state: state, phase: phase, allowed: allowed} <- @owner_cases do
      test "#{state}/#{inspect(phase)}" do
        owner_id = "owner"
        queue = ["player", "challenger", owner_id]
        game = game(unquote(state), unquote(phase), owner_id, queue)
        user_id = owner_id
        allowed = unquote(allowed)

        assert_allowed(game, user_id, allowed)
        assert_denied(game, user_id, @all_actions -- allowed)
      end
    end
  end

  describe "player policies" do
    for %{state: state, phase: phase, allowed: allowed} <- @player_cases do
      test "#{state}/#{inspect(phase)}" do
        owner_id = "owner"
        player_id = "player"
        queue = [player_id, "challenger"]
        game = game(unquote(state), unquote(phase), owner_id, queue)
        user_id = player_id
        allowed = unquote(allowed)

        assert_allowed(game, user_id, allowed)
        assert_denied(game, user_id, @all_actions -- allowed)
      end
    end
  end

  describe "challenger policies" do
    for %{state: state, phase: phase, allowed: allowed} <- @challenger_cases do
      test "#{state}/#{inspect(phase)}" do
        owner_id = "owner"
        challenger_id = "challenger"
        queue = ["player", challenger_id]
        game = game(unquote(state), unquote(phase), owner_id, queue)
        user_id = challenger_id
        allowed = unquote(allowed)

        assert_allowed(game, user_id, allowed)
        assert_denied(game, user_id, @all_actions -- allowed)
      end
    end
  end

  defp game(state, phase, owner_id, queue) do
    %Game{
      status: state,
      owner_id: owner_id,
      queue: queue,
      cursor: 0,
      turn:
        case state do
          :in_progress -> %Turn{phase: phase, timeline: [], assumptions: []}
          _ -> nil
        end
    }
  end

  defp assert_allowed(game, user_id, actions) do
    Enum.each(actions, fn action ->
      assert :ok == Bodyguard.permit(Songy.Policy, action, user_id, game)
    end)
  end

  defp assert_denied(game, user_id, actions) do
    Enum.each(actions, fn action ->
      assert {:error, :unauthorized} == Bodyguard.permit(Songy.Policy, action, user_id, game)
    end)
  end
end
