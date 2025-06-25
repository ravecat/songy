defmodule Songy.Core.User do
  @moduledoc """
  Represents a game user in the music year guessing quiz.

  This is separate from the authenticated user system and represents
  a player within a game session. Users are stored in memory during
  game sessions and not persisted to database.
  """

  use TypedStruct

  @derive {Jason.Encoder, only: [:uuid, :name, :avatar_url]}

  @uuid_size 16
  @base_avatar_url "https://api.dicebear.com/9.x"

  typedstruct do
    field :uuid, String.t(), enforce: true
    field :name, String.t()
    field :avatar_url, String.t()
  end

  @doc """
  Creates a new game user with random UUID.

  ## Examples
      iex> User.new()
      %User{uuid: "a1b2c3d4", name: "Pikachu"}
  """
  @spec new() :: t()
  def new() do
    uuid = generate_uuid()

    %__MODULE__{
      uuid: uuid,
      name: generate_name(uuid),
      avatar_url: generate_avatar_url(uuid)
    }
  end

  @doc """
  Gets or creates a game user with specified UUID.
  Uses deterministic data generation based on UUID.

  ## Examples
      iex> User.get_user("abc123")
      %User{uuid: "abc123", name: "Pikachu", avatar_url: "..."}

      iex> User.get_user("abc123")
      %User{uuid: "abc123", name: "Pikachu", avatar_url: "..."}  # Same name
  """
  @spec get_user(String.t()) :: t()
  def get_user(uuid) when is_binary(uuid) do
    %__MODULE__{
      uuid: uuid,
      name: generate_name(uuid),
      avatar_url: generate_avatar_url(uuid)
    }
  end

  defp generate_uuid do
    @uuid_size
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp generate_name(uuid) do
    <<a::32, b::32, c::32, _d::32, _rest::binary>> =
      :crypto.hash(:md5, uuid) <> <<0, 0, 0, 0>>

    old_state = :rand.export_seed()
    :rand.seed(:exsss, {a, b, c})

    name = Faker.Pokemon.name()

    case old_state do
      :undefined -> :ok
      _ -> :rand.seed(old_state)
    end

    name
  end

  defp generate_avatar_url(uuid) do
    "#{@base_avatar_url}/thumbs/svg?seed=#{uuid}"
  end
end
