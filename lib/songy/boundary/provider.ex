defmodule Songy.Boundary.Provider do
  @moduledoc """
  Behaviour for music provider implementations.

  Defines the required callbacks that all music providers (Spotify, Apple Music, etc.)
  must implement to work with the Songy game system.

  All methods use consistent `(creds, opts)` signature pattern for predictable API.

  ## Required Callbacks

    * `start_playback/2` - Starts playback with credentials and options
    * `pause_playback/2` - Pauses current playback with credentials and options
    * `search_random_track/2` - Searches for a random track with credentials and options

  ## Example Implementation

      defmodule MyMusicProvider do
        @behaviour Songy.Boundary.Provider

        @impl true
        def start_playback(creds, opts) do
          # opts contains: uris, device_id, position_ms, etc.
          {:ok, :playback_started}
        end

        @impl true
        def pause_playback(creds, opts) do
          # opts contains: device_id, etc.
          {:ok, :playback_paused}
        end

        @impl true
        def search_random_track(creds, opts) do
          # opts contains: market, limit, genre, etc.
          {:ok, %{name: "Random Song", artist: "Random Artist"}}
        end
      end
  """

  @doc """
  Starts playback for the provider.

  ## Parameters
    * `creds` - Provider-specific credentials/tokens map
    * `opts` - Keyword list with playback options:
      * `:uris` - List of track URIs to play
      * `:device_id` - Target device ID for playback
      * `:position_ms` - Start position in milliseconds (optional)
      * `:context_uri` - Playlist/album context (optional)

  ## Returns
    * `{:ok, :playback_started}` - Success
    * `{:error, reason}` - Failure with reason atom

  ## Examples
      iex> start_playback(creds, uris: ["spotify:track:123"], device_id: "device123")
      {:ok, :playback_started}
  """
  @callback start_playback(creds :: map(), opts :: keyword()) ::
    {:ok, :playback_started} | {:error, atom()}

  @doc """
  Pauses playback for the provider.

  ## Parameters
    * `creds` - Provider-specific credentials/tokens map
    * `opts` - Keyword list with pause options:
      * `:device_id` - Target device ID (optional)

  ## Returns
    * `{:ok, :playback_paused}` - Success
    * `{:error, reason}` - Failure with reason atom

  ## Examples
      iex> pause_playback(creds, device_id: "device123")
      {:ok, :playback_paused}
  """
  @callback pause_playback(creds :: map(), opts :: keyword()) ::
    {:ok, :playback_paused} | {:error, atom()}

  @doc """
  Searches for a random track from the provider.

  ## Parameters
    * `creds` - Provider-specific credentials/tokens map
    * `opts` - Keyword list with search options:
      * `:market` - Market/country code (optional)
      * `:limit` - Number of results (optional)
      * `:genre` - Genre filter (optional)

  ## Returns
    * `{:ok, track_data}` - Success with track information map
    * `{:error, reason}` - Failure with reason atom

  ## Examples
      iex> search_random_track(creds, market: "US", limit: 1)
      {:ok, %{name: "Random Song", artist: "Random Artist"}}
  """
  @callback search_random_track(creds :: map(), opts :: keyword()) ::
    {:ok, map()} | {:error, atom()}
end
