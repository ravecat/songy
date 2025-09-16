defmodule Songy.Core.Provider.Spotify do
  @moduledoc """
  Spotify provider embedded schema with authentication and device management fields.

  This schema handles Spotify OAuth tokens and device identification for playback control.
  All fields are optional to support partial updates during authentication flow.
  Implements Provider.Behaviour for consistent interface.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:expires_at, :access_token, :refresh_token, :device_id]}

  @type t :: %__MODULE__{
          expires_at: DateTime.t() | nil,
          access_token: String.t() | nil,
          refresh_token: String.t() | nil,
          device_id: String.t() | nil
        }

  @spotify_token_expires_in 3600

  @primary_key false
  embedded_schema do
    field :expires_at, :utc_datetime
    field :access_token, :string
    field :refresh_token, :string
    field :device_id, :string
  end

  @doc """
  Changeset function for casting and validating Spotify provider data.

  When access_token is present, casts token-related fields.
  When access_token is absent, casts only device_id.
  """
  def changeset(provider, %{access_token: token} = attrs) when not is_nil(token) do
    provider
    |> cast(attrs, [:expires_at, :access_token, :refresh_token])
    |> put_expires_at()
  end

  def changeset(provider, attrs) do
    cast(provider, attrs, [:device_id])
  end

  defp put_expires_at(changeset) do
    expires_at = DateTime.add(DateTime.utc_now(), @spotify_token_expires_in, :second)

    case changeset do
      %Ecto.Changeset{valid?: true} ->
        put_change(changeset, :expires_at, expires_at)

      _ ->
        changeset
    end
  end
end
