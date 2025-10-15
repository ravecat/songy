defprotocol Songy.Boundary.Player do
  @fallback_to_any true

  @moduledoc """
  Protocol for music provider playback operations.

  Defines a unified interface for controlling music playback across different
  music providers (Spotify, Apple Music, YouTube Music, etc.).

  All functions return standardized response tuples with generic error atoms
  for consistent error handling across the application.
  """

  @spec start_playback(t(), Songy.Core.Track.t()) :: {:ok, term()} | {:error, atom()}
  def start_playback(provider, track)

  @spec pause_playback(t()) :: {:ok, term()} | {:error, atom()}
  def pause_playback(provider)

  @spec search_random_track(t()) :: {:ok, Songy.Core.Track.t()} | {:error, atom()}
  def search_random_track(provider)
end

defimpl Songy.Boundary.Player, for: Any do
  def start_playback(_provider, _track), do: {:error, :not_supported}
  def pause_playback(_provider), do: {:error, :not_supported}
  def search_random_track(_provider), do: {:error, :not_supported}
end

defimpl Songy.Boundary.Player, for: Songy.Core.Provider.Spotify do
  alias Songy.Boundary.Spotify
  alias Songy.Core.Track
  alias Songy.Core.Trackable

  @doc """
  Starts Spotify playback by extracting URI from track metadata.

  Spotify-specific implementation:
  - Requires track.meta.uri for track identification
  - Uses provider.device_id for device targeting
  """
  def start_playback(%{device_id: device_id} = provider, %Track{meta: %{uri: uri}}) do
    Spotify.start_playback(provider, uris: [uri], device_id: device_id)
  end

  def start_playback(_provider, %Track{}) do
    {:error, :missing_track_uri}
  end

  @doc """
  Pauses Spotify playback on the active device.

  No track needed - Spotify API pauses current playback.
  """
  def pause_playback(provider) do
    Spotify.pause_playback(provider)
  end

  def search_random_track(provider) do
    case Spotify.search_random_track(provider) do
      {:ok, track} ->
        {:ok, Trackable.to_track(track)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
