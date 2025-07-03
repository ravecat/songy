defmodule Songy.Core.Provider do
  @moduledoc """
  Provides a common interface for media providers.
  """

  use TypedStruct

  typedstruct do
    field :id, atom()
    field :meta, map()
  end

  def new(id, meta \\ %{}) do
    %__MODULE__{id: id, meta: meta}
  end
end
