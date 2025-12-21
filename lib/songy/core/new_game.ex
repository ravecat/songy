defmodule Songy.Core.NewGame do
  @moduledoc """
  Game state structure for FSM-based game management.

  This module defines the pure data structure for a game without any business logic.
  All game logic is handled by `Songy.Boundary.Game` FSM.
  """

  @derive {Jason.Encoder,
           only: [
             :id,
             :owner_uuid,
             :max_participants,
             :max_score,
             :status,
             :participants,
             :scores,
             :player,
             :timelines,
             :created_at,
             :turn
           ]}

  alias Songy.Core.NewTurn
  alias Songy.Core.Player
  alias Songy.Core.Track
  alias Songy.Core.User

  defstruct [
    :id,
    :owner_uuid,
    :max_participants,
    :max_score,
    :status,
    :participants,
    :scores,
    :player,
    :timelines,
    :created_at,
    :turn
  ]

  @typedoc "Unique game identifier"
  @type id :: String.t()

  @typedoc "Game owner UUID"
  @type owner_uuid :: String.t()

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

  @typedoc "Current turn state"
  @type turn :: NewTurn.t() | nil

  @typedoc "Game structure"
  @type t :: %__MODULE__{
          id: id,
          owner_uuid: owner_uuid,
          max_participants: max_participants,
          max_score: max_score,
          status: status,
          participants: participants,
          scores: scores,
          player: player,
          timelines: timelines,
          created_at: created_at,
          turn: turn
        }
end
