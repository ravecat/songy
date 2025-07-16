defmodule Songy.Core.Provider do
  @moduledoc """
  Simple provider structure with id and metadata fields using basic Elixir types.
  """

  use Ecto.Schema
  import PolymorphicEmbed
  import Ecto.Changeset

  alias Songy.Core.Provider.Spotify

  @derive {Jason.Encoder, only: [:id, :meta]}

  @type provider_meta :: Spotify.t() | nil
  @type t :: %__MODULE__{
          id: atom(),
          meta: provider_meta()
        }

  @primary_key false
  embedded_schema do
    field :id, Ecto.Enum, values: [:spotify]

    polymorphic_embeds_one :meta,
      types: [
        spotify: Spotify
      ],
      on_replace: :update,
      use_parent_field_for_type: :id
  end

  @doc """
  Creates a new provider instance with given id and metadata.

  ## Examples

      iex> Provider.new(:spotify, %{access_token: "token"})
      %Provider{id: :spotify, meta: %Spotify{access_token: "token"}}
  """

  @spec new(atom(), map()) :: %__MODULE__{} | {:error, Ecto.Changeset.t()}
  def new(id, meta \\ %{}) do
    %__MODULE__{}
    |> cast(%{id: id, meta: meta}, [:id])
    |> case do
      %{valid?: true} = changeset ->
        changeset
        |> cast_polymorphic_embed(:meta)
        |> apply_changes()

      %{valid?: false} = changeset ->
        {:error, changeset}
    end
  end

  @spec update(%__MODULE__{}, map()) :: %__MODULE__{} | {:error, Ecto.Changeset.t()}
  def update(%__MODULE__{} = provider, attrs) do
    provider
    |> cast(%{id: provider.id, meta: attrs}, [:id])
    |> case do
      %{valid?: true} = changeset ->
        changeset
        |> cast_polymorphic_embed(:meta)
        |> apply_changes()

      %{valid?: false} = changeset ->
        {:error, changeset}
    end
  end
end
