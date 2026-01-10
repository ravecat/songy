defmodule Songy.Policy do
  @moduledoc """
  Authorization policy for game actions.
  """

  @behaviour Bodyguard.Policy

  alias Songy.Core.Game

  @spec authorize(atom(), String.t() | nil, Game.t() | nil) :: :ok | {:error, :unauthorized}
  def authorize(_action, _user_id, nil), do: {:error, :unauthorized}
  def authorize(_action, nil, _game), do: {:error, :unauthorized}

  def authorize(action, user, game) do
    status = status(game)
    subject = subject(game, user)
    phase = phase(game)

    can(action, subject, status, phase)
  end

  defp can(_action, nil, _status, _phase), do: {:error, :unauthorized}

  defp can(:start_game, :owner, :waiting, _phase), do: :ok

  defp can(action, subject, :in_progress, phase)
       when action in [:start_playback, :pause_playback] and phase in [:waiting, :ready] and
              subject in [:owner, :player],
       do: :ok

  defp can(action, subject, :in_progress, :challenging)
       when action in [:start_playback, :pause_playback] and subject in [:owner, :challenger],
       do: :ok

  defp can(:next_phase, subject, :in_progress, :waiting) when subject in [:owner, :player], do: :ok
  defp can(:next_phase, :player, :in_progress, :ready), do: :ok
  defp can(:next_phase, subject, :in_progress, :results) when subject in [:owner, :player], do: :ok

  defp can(action, :owner, :in_progress, phase)
       when action in [:make_assumption, :reorder_timeline] and phase in [:ready, :challenging],
       do: :ok

  defp can(_action, _subject, _status, _phase), do: {:error, :unauthorized}

  defp subject(_game, nil), do: nil

  defp subject(game, user_id) do
    is_owner = game.owner_id == user_id
    active_player = Enum.at(game.queue, game.cursor)
    is_active = active_player == user_id

    cond do
      is_owner -> :owner
      is_active -> :player
      true -> :challenger
    end
  end

  defp status(%Game{status: status}), do: status
  defp status(_), do: nil

  defp phase(%Game{turn: %{phase: phase}}), do: phase
  defp phase(_), do: nil
end
