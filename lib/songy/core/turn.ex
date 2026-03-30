defmodule Songy.Core.Turn do
  @moduledoc """
  Game turn state structure.
  """

  @derive {Jason.Encoder, only: [:phase, :assumptions, :winner_id, :deadline_at_ms]}

  defstruct [
    :phase,
    :assumptions,
    :winner_id,
    :deadline_at_ms
  ]

  @typedoc "Turn phase"
  @type phase :: :waiting | :ready | :challenging | :results

  @typedoc "Player assumptions map keyed by position"
  @type assumptions :: %{non_neg_integer() => String.t()}

  @type winner :: String.t() | nil
  @type deadline_at_ms :: non_neg_integer() | nil

  @typedoc "Turn structure"
  @type t :: %__MODULE__{
          phase: phase,
          assumptions: assumptions,
          winner_id: winner,
          deadline_at_ms: deadline_at_ms
        }
end
