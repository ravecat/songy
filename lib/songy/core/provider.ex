defmodule Songy.Core.Provider do
  @moduledoc """
  Provides a common interface for media providers.
  """

  use TypedStruct

  typedstruct do
    field :id, atom(), enforce: true
    field :meta, map(), default: %{}
  end

  def new(id, meta \\ %{}) do
    %__MODULE__{id: id, meta: meta}
  end
end
