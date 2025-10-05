defmodule Songy.Core.Provider.Spotify do
  @moduledoc """
  Represents Spotify provider struct.

  Contains authentication tokens, expiration time, and device information needed
  for Spotify Web API access and Web Playback SDK integration.
  """

  use TypeCheck
  use TypeCheck.Defstruct

  @token_refresh_threshold 3600
  @derive {Jason.Encoder, only: [:access_token, :refresh_token, :expires_at, :device_id]}

  defstruct!(
    access_token: _ :: String.t(),
    refresh_token: _ :: String.t(),
    device_id: nil :: String.t() | nil,
    expires_at: nil :: DateTime.t()
  )

  @spec! new(%{optional(atom) => any} | keyword) :: t()
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    struct(__MODULE__, attrs)
    |> with_expires_at()
  end

  @spec! update(t(), %{optional(atom) => any} | keyword) :: t()
  def update(%__MODULE__{} = provider, attrs) when is_map(attrs) or is_list(attrs) do
    struct(provider, attrs)
    |> with_expires_at()
  end

  defp with_expires_at(%__MODULE__{} = provider, threshold_seconds \\ @token_refresh_threshold) do
    expires_at = DateTime.add(DateTime.utc_now(), threshold_seconds, :second)
    struct(provider, expires_at: expires_at)
  end
end
