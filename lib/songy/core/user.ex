defmodule Songy.Core.User do
  @moduledoc """
  Represents a game user in the music year guessing quiz.

  This is separate from the authenticated user system and represents
  a player within a game session. Users are stored in memory during
  game sessions and not persisted to database.
  """

  use TypedStruct

  @uuid_size 16

  typedstruct do
    field :uuid, String.t(), enforce: true
  end

  @doc """
  Creates a new game user.

  ## Examples
      iex> User.new()
      %User{uuid: "a1b2c3d4"}
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      uuid: generate_uuid()
    }
  end

  defp generate_uuid do
    @uuid_size
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end
end
