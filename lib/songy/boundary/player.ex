defprotocol Songy.Boundary.Player do
  @fallback_to_any true

  @moduledoc """
  Protocol for music provider playback operations.

  Defines a unified interface for controlling music playback across different
  music providers (Spotify, Apple Music, YouTube Music, etc.).

  All functions return standardized response tuples with generic error atoms
  for consistent error handling across the application.
  """

  @spec start_playback(t(), keyword()) :: {:ok, term()} | {:error, atom()}
  def start_playback(provider, opts)

  @spec pause_playback(t(), keyword()) :: {:ok, term()} | {:error, atom()}
  def pause_playback(provider, opts \\ [])

  @spec search_random_track(t()) :: {:ok, Songy.Core.Track.t()} | {:error, atom()}
  def search_random_track(provider)
end

defimpl Songy.Boundary.Player, for: Any do
  def start_playback(_provider, _opts), do: {:error, :not_supported}
  def pause_playback(_provider, _opts), do: {:error, :not_supported}
  def search_random_track(_provider), do: {:error, :not_supported}
end

defimpl Songy.Boundary.Player, for: Songy.Core.Provider.Spotify do
  alias Songy.Boundary.Spotify
  alias Songy.Core.Trackable

  defdelegate start_playback(provider, opts), to: Spotify
  defdelegate pause_playback(provider, opts), to: Spotify

  def search_random_track(provider) do
    case Spotify.search_random_track(provider) do
      {:ok, track} ->
        {:ok, Trackable.to_track(track)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
