defmodule Songy.Core.Provider.Mock do
  @moduledoc """
  In-memory provider used to make test runs deterministic and network-free.
  """

  defstruct []

  @type t :: %__MODULE__{}

  @spec new() :: t()
  def new, do: %__MODULE__{}
end
