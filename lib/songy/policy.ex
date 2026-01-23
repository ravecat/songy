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
    :see_assumptions
  ]

  def acts, do: @acts

  @spec authorize(atom(), String.t() | nil, Game.t() | nil) :: :ok | {:error, :unauthorized}
  def authorize(_action, _user_id, nil), do: {:error, :unauthorized}
  def authorize(_action, nil, _game), do: {:error, :unauthorized}

  def authorize(action, user, game) do
    subjects = Game.roles(game, user)

    if Enum.any?(subjects, &can?(action, &1, user, game)) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  defp can?(:advance_turn, :player, _user_id, %Game{status: :in_progress, turn: %{phase: :ready}} = game) do
    Game.has_assumption?(game, Enum.at(game.queue, game.cursor))
  end

  defp can?(:advance_turn, :player, _user_id, %Game{status: :in_progress, turn: %{phase: :waiting}}), do: true
  defp can?(:advance_turn, :player, _user_id, %Game{status: :in_progress, turn: %{phase: :results}}), do: true
  defp can?(:advance_turn, :owner, _user_id, %Game{status: :in_progress, turn: %{phase: :waiting}}), do: true

  defp can?(:advance_turn, :owner, _user_id, %Game{status: :in_progress, turn: %{phase: :ready}} = game) do
    Game.has_assumption?(game, Enum.at(game.queue, game.cursor))
  end

  defp can?(:advance_turn, :owner, _user_id, %Game{status: :in_progress, turn: %{phase: :results}}), do: true

  defp can?(:start_turn, :player, _user_id, %Game{status: :in_progress, turn: %{phase: :waiting}}), do: true
  defp can?(:start_turn, :owner, _user_id, %Game{status: :in_progress, turn: %{phase: :waiting}}), do: true

  defp can?(:start_game, :owner, _user_id, %Game{status: :waiting}), do: true

  defp can?(:control_playback, :player, _user_id, %Game{status: :in_progress, turn: %{phase: :ready}}), do: true
  defp can?(:control_playback, :player, _user_id, %Game{status: :in_progress, turn: %{phase: :results}}), do: true
  defp can?(:control_playback, :owner, _user_id, %Game{status: :in_progress, turn: %{phase: :results}}), do: true
  defp can?(:control_playback, :owner, _user_id, %Game{status: :in_progress, turn: %{phase: :ready}}), do: true

  defp can?(:control_playback, :challenger, _user_id, %Game{status: :in_progress, turn: %{phase: :challenging}}),
    do: true

  defp can?(:control_playback, :owner, _user_id, %Game{status: :in_progress, turn: %{phase: :challenging}}), do: true

  defp can?(:restart_game, :owner, _user_id, %Game{status: :finished}), do: true

  defp can?(:make_assumption, :player, _user_id, %Game{status: :in_progress, turn: %{phase: :ready}}), do: true

  defp can?(:make_assumption, :challenger, _user_id, %Game{status: :in_progress, turn: %{phase: :challenging}}),
    do: true

  defp can?(:see_assumptions, _, _user_id, %Game{status: :in_progress, turn: %{phase: :results}}), do: true

  defp can?(_action, _subject, _user_id, %Game{}), do: false
end
