defmodule Songy.Authorization do
  @moduledoc """
  Authorization checks for game actions.

  This module delegates to `Songy.Policy` and provides helper functions for
  computing UI permissions.
  """

  alias Songy.Core.Game
  alias Songy.Policy

  @doc """
  Checks if a user can perform an action in a game context.

  Returns :ok if authorized, {:error, :unauthorized} otherwise.
  """
  @spec can?(Game.t() | nil, String.t() | nil, atom()) :: :ok | {:error, :unauthorized}
  def can?(game, user_id, action) do
    Bodyguard.permit(Policy, action, user_id, game)
  end

  @doc """
  Computes permissions for a user in a game context.
  """
  @spec permissions(Game.t() | nil, String.t() | nil) :: %{
          can_control_playback: boolean(),
          can_advance_turn: boolean(),
          can_start_game: boolean(),
          can_ready: boolean(),
          can_restart_game: boolean()
        }
  def permissions(nil, _user_id), do: default_permissions()
  def permissions(_game, nil), do: default_permissions()

  def permissions(%Game{} = game, user_id) do
    status = game.status
    phase = phase(game)

    %{
      can_control_playback: can_control_playback?(game, user_id),
      can_advance_turn: can_advance_turn?(game, user_id, status, phase),
      can_start_game: can_start_game?(game, user_id, status, phase),
      can_ready: can_ready?(game, user_id, status, phase),
      can_restart_game: can_restart_game?(game, user_id, status)
    }
  end

  defp default_permissions do
    %{
      can_control_playback: false,
      can_advance_turn: false,
      can_start_game: false,
      can_ready: false,
      can_restart_game: false
    }
  end

  defp can_control_playback?(game, user_id) do
    Bodyguard.permit?(Policy, :start_playback, user_id, game) or
      Bodyguard.permit?(Policy, :pause_playback, user_id, game)
  end

  defp can_advance_turn?(game, user_id, :in_progress, phase) when phase in [:ready, :results] do
    Bodyguard.permit?(Policy, :next_phase, user_id, game)
  end

  defp can_advance_turn?(_game, _user_id, _status, _phase), do: false

  defp can_ready?(game, user_id, :in_progress, :waiting) do
    Bodyguard.permit?(Policy, :next_phase, user_id, game)
  end

  defp can_ready?(_game, _user_id, _status, _phase), do: false

  defp can_start_game?(game, user_id, :waiting, _phase) do
    Bodyguard.permit?(Policy, :start_game, user_id, game)
  end

  defp can_start_game?(_game, _user_id, _status, _phase), do: false

  defp can_restart_game?(%Game{owner_id: owner_id}, user_id, :finished) do
    owner_id == user_id
  end

  defp can_restart_game?(_game, _user_id, _status), do: false

  defp phase(%Game{turn: %{phase: phase}}), do: phase
  defp phase(_), do: nil
end
