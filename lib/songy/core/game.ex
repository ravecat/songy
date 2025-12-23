defmodule Songy.Core.Game do
  @moduledoc """
  Game state structure for FSM-based game management.

  This module defines the pure data structure for a game without any business logic.
  All game logic is handled by `Songy.Boundary.Game` FSM.
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

  alias Songy.Core.Turn
  alias Songy.Core.Player
  alias Songy.Core.Track
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
end
