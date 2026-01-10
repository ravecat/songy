defmodule Songy.Policy do
  @moduledoc """
  Authorization policy for game actions.
  """

  @behaviour Bodyguard.Policy

  alias Songy.Core.Game

  @acts [
    :start_game,
    :start_playback,
    :pause_playback,
    :next_phase,
    :make_assumption,
    :reorder_timeline,
    :spectate
  ]

  def acts, do: @acts

  @spec authorize(atom(), String.t() | nil, Game.t() | nil) :: :ok | {:error, :unauthorized}
  def authorize(_action, _user_id, nil), do: {:error, :unauthorized}
  def authorize(_action, nil, _game), do: {:error, :unauthorized}

  def authorize(action, user, game) do
    status = status(game)
    subjects = subjects(game, user)
    phase = phase(game)

    if Enum.any?(subjects, fn subj -> can(action, subj, status, phase) == :ok end) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  defp can(_action, nil, _status, _phase), do: {:error, :unauthorized}

  defp can(:start_game, :owner, :waiting, _phase), do: :ok

  defp can(:start_playback, :owner, :in_progress, :waiting), do: :ok
  defp can(:start_playback, :player, :in_progress, :waiting), do: :ok
  defp can(:start_playback, :owner, :in_progress, :ready), do: :ok
  defp can(:start_playback, :player, :in_progress, :ready), do: :ok

  defp can(:pause_playback, :owner, :in_progress, :waiting), do: :ok
  defp can(:pause_playback, :player, :in_progress, :waiting), do: :ok
  defp can(:pause_playback, :owner, :in_progress, :ready), do: :ok
  defp can(:pause_playback, :player, :in_progress, :ready), do: :ok

  defp can(:start_playback, :owner, :in_progress, :challenging), do: :ok
  defp can(:start_playback, :challenger, :in_progress, :challenging), do: :ok

  defp can(:pause_playback, :owner, :in_progress, :challenging), do: :ok
  defp can(:pause_playback, :challenger, :in_progress, :challenging), do: :ok

  defp can(:next_phase, :owner, :in_progress, :waiting), do: :ok
  defp can(:next_phase, :player, :in_progress, :waiting), do: :ok
  defp can(:next_phase, :player, :in_progress, :ready), do: :ok
  defp can(:next_phase, :owner, :in_progress, :results), do: :ok
  defp can(:next_phase, :player, :in_progress, :results), do: :ok

  defp can(:make_assumption, :owner, :in_progress, :ready), do: :ok
  defp can(:make_assumption, :owner, :in_progress, :challenging), do: :ok

  defp can(:reorder_timeline, :owner, :in_progress, :ready), do: :ok
  defp can(:reorder_timeline, :owner, :in_progress, :challenging), do: :ok

  defp can(_action, _subject, _status, _phase), do: {:error, :unauthorized}

  defp subjects(_game, nil), do: []

  defp subjects(game, user_id) do
    active_player = Enum.at(game.queue, game.cursor)
    is_active = active_player == user_id
    is_owner = game.owner_id == user_id

    cond do
      is_owner and is_active -> [:player, :owner]
      is_owner -> [:owner]
      is_active -> [:player]
      true -> [:challenger]
    end
  end

  defp status(%Game{status: status}), do: status
  defp status(_), do: nil

  defp phase(%Game{turn: %{phase: phase}}), do: phase
  defp phase(_), do: nil
end
