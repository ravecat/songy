defmodule Songy.Core.Provider.ITunes do
  @moduledoc """
  Represents iTunes provider struct.

  Empty struct serves as a type marker for pattern matching with different providers.
  """

  defstruct []

  @type t :: %__MODULE__{}

  @spec new() :: t()
  def new, do: %__MODULE__{}
end
