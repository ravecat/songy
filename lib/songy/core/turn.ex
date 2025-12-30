defmodule Songy.Core.Turn do
  @moduledoc """
  Game turn state structure.
  """

  @derive {Jason.Encoder, only: [:phase, :timeline, :assumptions]}

  defstruct [
    :phase,
    :timeline,
    :assumptions
  ]

  @typedoc "Turn phase"
  @type phase :: :waiting | :ready | :challenging | :results

  @typedoc "Timeline for challenging phase"
  @type timeline :: list(Songy.Core.Track.t())

  @typedoc "Player assumptions"
  @type assumptions :: list(%{position: non_neg_integer(), user_id: String.t()})

  @typedoc "Turn structure"
  @type t :: %__MODULE__{
          phase: phase,
          timeline: timeline,
          assumptions: assumptions
        }
end
