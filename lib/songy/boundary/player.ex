defprotocol Songy.Boundary.Player do
  @fallback_to_any true

  @moduledoc """
  Protocol for music provider playback operations.

  Defines a unified interface for controlling music playback across different
  music providers (Spotify, Apple Music, YouTube Music, etc.).

  All functions return standardized response tuples with generic error atoms
  for consistent error handling across the application.
  """

  @spec start_playback(t(), keyword()) :: {:ok, :started} | {:error, atom()}
  def start_playback(provider, opts)

  @spec pause_playback(t(), keyword()) :: {:ok, :paused} | {:error, atom()}
  def pause_playback(provider, opts \\ [])

  @spec search(t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def search(provider, query, opts \\ [])
end

defimpl Songy.Boundary.Player, for: Any do
  def start_playback(_provider, _opts), do: {:error, :not_supported}
  def pause_playback(_provider, _opts), do: {:error, :not_supported}
  def search(_provider, _opts), do: {:error, :not_supported}
end
