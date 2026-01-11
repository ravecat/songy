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
          can_start_turn: boolean(),
          can_restart_game: boolean()
        }
  def permissions(nil, _user_id), do: default_permissions()
  def permissions(_game, nil), do: default_permissions()

  def permissions(%Game{} = game, user_id) do
    %{
      can_control_playback: Bodyguard.permit?(Policy, :control_playback, user_id, game),
      can_advance_turn: Bodyguard.permit?(Policy, :advance_turn, user_id, game),
      can_start_game: Bodyguard.permit?(Policy, :start_game, user_id, game),
      can_start_turn: Bodyguard.permit?(Policy, :start_turn, user_id, game),
      can_restart_game: Bodyguard.permit?(Policy, :restart_game, user_id, game)
    }
  end

  defp default_permissions do
    %{
      can_control_playback: false,
      can_advance_turn: false,
      can_start_game: false,
      can_start_turn: false,
      can_restart_game: false
    }
  end
end
