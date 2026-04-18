defmodule Songy.Core.User do
  @moduledoc """
  Represents a game user in the music year guessing quiz.

  This is separate from the authenticated user system and represents
  a player within a game session. Users are stored in memory during
  game sessions and not persisted to database.
  """

  use TypedStruct

  @derive {Jason.Encoder, only: [:id, :name, :avatar_url]}

  @id_size 16
  @base_avatar_url "https://api.dicebear.com/9.x"

  typedstruct do
    field :id, String.t(), enforce: true
    field :name, String.t()
    field :avatar_url, String.t()
  end

  @doc """
  Creates a new game user with a random id.

  ## Examples
      iex> User.new()
      %User{id: "a1b2c3d4", name: "Brave Lion"}
  """
  @spec new() :: t()
  def new() do
    id = generate_id()

    %__MODULE__{
      id: id,
      name: generate_name(id),
      avatar_url: generate_avatar_url(id)
    }
  end

  @doc """
  Gets or creates a game user with a specified id.
  Uses deterministic data generation based on the id.

  ## Examples
      iex> User.get_user("abc123")
      %User{id: "abc123", name: "Quick Fox", avatar_url: "..."}

      iex> User.get_user("abc123")
      %User{id: "abc123", name: "Quick Fox", avatar_url: "..."}  # Same name
  """
  @spec get_user(String.t()) :: t()
  def get_user(id) when is_binary(id) do
    %__MODULE__{
      id: id,
      name: generate_name(id),
      avatar_url: generate_avatar_url(id)
    }
  end

  defp generate_id do
    @id_size
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp generate_name(id) do
    seed = :erlang.phash2(id)

    UniqueNamesGenerator.generate(
      [:adjectives, :animals],
      %{seed: seed, style: :capital, separator: " "}
    )
  end

  defp generate_avatar_url(id) do
    "#{@base_avatar_url}/thumbs/svg?seed=#{id}"
  end
end
