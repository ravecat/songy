defmodule Songy.Core.Provider.Spotify do
  @moduledoc """
  Represents Spotify provider struct.

  Contains authentication tokens, expiration time, and device information needed
  for Spotify Web API access and Web Playback SDK integration.
  """

  @token_refresh_threshold 3600
  @derive {Jason.Encoder, only: [:access_token, :refresh_token, :expires_at, :device_id]}

  defstruct access_token: nil,
            refresh_token: nil,
            device_id: nil,
            expires_at: nil

  @typedoc "Spotify provider instance"
  @type t :: %__MODULE__{
          access_token: String.t() | nil,
          refresh_token: String.t() | nil,
          device_id: String.t() | nil,
          expires_at: DateTime.t() | nil
        }

  @doc "Creates a new Spotify provider from attributes"
  @spec new(%{optional(atom) => any} | keyword) :: t()
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    struct(__MODULE__, attrs)
    |> with_expires_at()
  end

  @doc "Updates existing Spotify provider with new attributes"
  @spec update(t(), %{optional(atom) => any} | keyword) :: t()
  def update(%__MODULE__{} = provider, attrs) when is_map(attrs) or is_list(attrs) do
    struct(provider, attrs)
    |> with_expires_at()
  end

  defp with_expires_at(%__MODULE__{} = provider, threshold_seconds \\ @token_refresh_threshold) do
    expires_at = DateTime.add(DateTime.utc_now(), threshold_seconds, :second)
    struct(provider, expires_at: expires_at)
  end
end
