defmodule Songy.Policy do
  @moduledoc """
  Authorization policy for game actions.
  """

  @behaviour Bodyguard.Policy

  alias Songy.Core.Game

  @acts [
    :start_game,
    :control_playback,
    :advance_turn,
    :start_turn,
    :restart_game,
    :make_assumption,
    :see_assumptions,
  ]

  def acts, do: @acts

  @spec authorize(atom(), String.t() | nil, Game.t() | nil) :: :ok | {:error, :unauthorized}
  def authorize(_action, _user_id, nil), do: {:error, :unauthorized}
  def authorize(_action, nil, _game), do: {:error, :unauthorized}

  def authorize(action, user, game) do
    subjects = subjects(game, user)

    if Enum.any?(subjects, fn subj -> can(action, subj, game) == :ok end) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  defp can(_action, nil, _game), do: {:error, :unauthorized}

  defp can(:start_game, :owner, %Game{status: :waiting}), do: :ok

  defp can(:control_playback, :player, %Game{status: :in_progress, turn: %{phase: :ready}}), do: :ok
  defp can(:control_playback, :player, %Game{status: :in_progress, turn: %{phase: :results}}), do: :ok
  defp can(:control_playback, :owner, %Game{status: :in_progress, turn: %{phase: :results}}), do: :ok
  defp can(:control_playback, :owner, %Game{status: :in_progress, turn: %{phase: :ready}}), do: :ok
  defp can(:control_playback, :challenger, %Game{status: :in_progress, turn: %{phase: :challenging}}), do: :ok
  defp can(:control_playback, :owner, %Game{status: :in_progress, turn: %{phase: :challenging}}), do: :ok

  defp can(:advance_turn, :player, %Game{status: :in_progress, turn: %{phase: :waiting}}), do: :ok
  defp can(:advance_turn, :player, %Game{status: :in_progress, turn: %{phase: :ready}}), do: :ok
  defp can(:advance_turn, :player, %Game{status: :in_progress, turn: %{phase: :results}}), do: :ok
  defp can(:advance_turn, :owner, %Game{status: :in_progress, turn: %{phase: :waiting}}), do: :ok
  defp can(:advance_turn, :owner, %Game{status: :in_progress, turn: %{phase: :ready}}), do: :ok
  defp can(:advance_turn, :owner, %Game{status: :in_progress, turn: %{phase: :results}}), do: :ok

  defp can(:start_turn, :player, %Game{status: :in_progress, turn: %{phase: :waiting}}), do: :ok
  defp can(:start_turn, :owner, %Game{status: :in_progress, turn: %{phase: :waiting}}), do: :ok

  defp can(:restart_game, :owner, %Game{status: :finished}), do: :ok

  defp can(:make_assumption, :player, %Game{status: :in_progress, turn: %{phase: :ready}}), do: :ok
  defp can(:make_assumption, :challenger, %Game{status: :in_progress, turn: %{phase: :challenging}}), do: :ok

  defp can(:see_assumptions, _, %Game{status: :in_progress, turn: %{phase: :results}}), do: :ok

  defp can(_action, _subject, %Game{}), do: {:error, :unauthorized}

  defp subjects(%Game{}, nil), do: []

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
end
