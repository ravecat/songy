defmodule Songy.Core.Turn do
  @moduledoc """
  Game turn state structure.
  """

  @derive {Jason.Encoder, only: [:phase, :assumptions]}

  defstruct [
    :phase,
    :assumptions
  ]

  @typedoc "Turn phase"
  @type phase :: :waiting | :ready | :challenging | :results

  @typedoc "Player assumptions"
  @type assumptions :: list(%{position: non_neg_integer(), user_id: String.t()})

  @typedoc "Turn structure"
  @type t :: %__MODULE__{
          phase: phase,
          assumptions: assumptions
        }
end
