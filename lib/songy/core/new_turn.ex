defmodule Songy.Core.NewTurn do
  @moduledoc """
  Game turn state structure.
  """

  @derive {Jason.Encoder, only: [:queue, :cursor, :track, :phase, :timeline, :assumptions]}

  defstruct [
    :game_id,
    :queue,
    :cursor,
    :track,
    :phase,
    :timeline,
    :assumptions
  ]

  @typedoc "Game ID"
  @type game_id :: String.t()

  @typedoc "Players queue"
  @type queue :: list(String.t())

  @typedoc "Current player index"
  @type cursor :: non_neg_integer()

  @typedoc "Current track"
  @type track :: Songy.Core.Track.t() | nil

  @typedoc "Turn phase"
  @type phase :: :waiting | :ready | :steady | :challenging | :results

  @typedoc "Timeline for challenging phase"
  @type timeline :: list(Songy.Core.Track.t())

  @typedoc "Player assumptions"
  @type assumptions :: list(%{position: non_neg_integer(), user_id: String.t()})

  @typedoc "Turn structure"
  @type t :: %__MODULE__{
          game_id: game_id,
          queue: queue,
          cursor: cursor,
          track: track,
          phase: phase,
          timeline: timeline,
          assumptions: assumptions
        }
end
