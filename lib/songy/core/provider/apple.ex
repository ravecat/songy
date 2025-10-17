defmodule Songy.Core.Provider.Apple do
  @moduledoc """
  Represents Apple Music provider struct.

  Empty struct serves as a type marker for pattern matching with different providers.
  """

  defstruct []

  @type t :: %__MODULE__{}

  @spec new() :: t()
  def new, do: %__MODULE__{}
end
