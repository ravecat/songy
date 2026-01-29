defmodule Songy.Core.Turn do
  @moduledoc """
  Game turn state structure.
  """

  @derive {Jason.Encoder, only: [:phase, :assumptions, :winner_id]}

  defstruct [
    :phase,
    :assumptions,
    :winner_id
  ]

  @typedoc "Turn phase"
  @type phase :: :waiting | :ready | :challenging | :results

  @typedoc "Player assumptions"
  @type assumptions :: list(%{position: non_neg_integer(), user_id: String.t()})

  @type winner :: String.t() | nil

  @typedoc "Turn structure"
  @type t :: %__MODULE__{
          phase: phase,
          assumptions: assumptions,
          winner_id: winner
        }
end
