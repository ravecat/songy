defmodule Songy.Core.Game do
  @moduledoc """
  Game state structure for FSM-based game management.

  This module defines the data structure for a game and provides validation helpers
  used by `Songy.Boundary.Game` FSM.
  """

  @derive {Jason.Encoder,
           only: [
             :id,
             :owner_id,
             :max_participants,
             :max_score,
             :status,
             :participants,
             :scores,
             :player,
             :timelines,
             :created_at,
             :queue,
             :cursor,
             :track,
             :turn
           ]}

  alias Songy.Core.Player
  alias Songy.Core.Track
  alias Songy.Core.Turn
  alias Songy.Core.User

  defstruct [
    :id,
    :owner_id,
    :max_participants,
    :max_score,
    :status,
    :participants,
    :scores,
    :player,
    :timelines,
    :created_at,
    :queue,
    :cursor,
    :track,
    :turn
  ]

  @typedoc "Unique game identifier"
  @type id :: String.t()

  @typedoc "Game owner UUID"
  @type owner_id :: String.t()

  @typedoc "Maximum number of participants allowed"
  @type max_participants :: pos_integer()

  @typedoc "Score needed to win the game"
  @type max_score :: pos_integer()

  @typedoc "Game status/phase"
  @type status :: :waiting | :in_progress | :finished

  @typedoc "List of participating users"
  @type participants :: list(User.t())

  @typedoc "Player scores map"
  @type scores :: %{String.t() => integer()}

  @typedoc "Playback state"
  @type player :: Player.t() | nil

  @typedoc "User timelines (chronologically ordered tracks)"
  @type timelines :: %{String.t() => list(Track.t())}

  @typedoc "Game creation timestamp"
  @type created_at :: DateTime.t()

  @typedoc "Players queue"
  @type queue :: list(String.t())

  @typedoc "Current player index"
  @type cursor :: non_neg_integer()

  @typedoc "Current track"
  @type track :: Track.t() | nil

  @typedoc "Current turn state"
  @type turn :: Turn.t() | nil

  @typedoc "Game structure"
  @type t :: %__MODULE__{
          id: id,
          owner_id: owner_id,
          max_participants: max_participants,
          max_score: max_score,
          status: status,
          participants: participants,
          scores: scores,
          player: player,
          timelines: timelines,
          created_at: created_at,
          queue: queue,
          cursor: cursor,
          track: track,
          turn: turn
        }

  @doc false
  @spec valid_assumption?(list(Track.t()), non_neg_integer()) :: boolean()
  def valid_assumption?(timeline, position) do
    case Enum.at(timeline, position) do
      nil ->
        false

      %Track{year: year} ->
        left_neighbor = if position > 0, do: Enum.at(timeline, position - 1), else: nil
        right_neighbor = Enum.at(timeline, position + 1)

        left_valid = is_nil(left_neighbor) or left_neighbor.year <= year
        right_valid = is_nil(right_neighbor) or year <= right_neighbor.year

        left_valid and right_valid
    end
  end

  @doc false
  @spec validate_not_full(t()) :: :ok | {:error, :game_full}
  def validate_not_full(%__MODULE__{} = game) do
    if length(game.participants) < game.max_participants do
      :ok
    else
      {:error, :game_full}
    end
  end

  @doc false
  @spec validate_not_duplicate(t(), User.t()) :: :ok | {:error, :already_joined}
  def validate_not_duplicate(%__MODULE__{} = game, %User{} = user) do
    if Enum.any?(game.participants, &(&1.uuid == user.uuid)) do
      {:error, :already_joined}
    else
      :ok
    end
  end

  @doc false
  @spec validate_min_participants(t()) :: :ok | {:error, :insufficient_participants}
  def validate_min_participants(%__MODULE__{} = game) do
    if length(game.participants) >= 2 do
      :ok
    else
      {:error, :insufficient_participants}
    end
  end

  @doc false
  @spec check_winner(t()) :: {:winner, String.t()} | :no_winner
  def check_winner(%__MODULE__{} = game) do
    Enum.find_value(game.scores, :no_winner, fn {user_id, score} ->
      if score >= game.max_score, do: {:winner, user_id}
    end)
  end

end
