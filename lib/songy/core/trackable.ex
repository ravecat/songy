defprotocol Songy.Core.Trackable do
  @moduledoc """
  Protocol for converting provider-specific track data to Track struct.

  This protocol enables transformation of various music provider data formats
  (Spotify, Apple Music, etc.) into the standardized `Songy.Core.Track` format
  used throughout the application.

  ## Examples

      iex> spotify_track = %Spotify.Track{id: "123", name: "Song", artists: [%{"name" => "Artist"}]}
      iex> Trackable.to_track(spotify_track)
      %Track{title: "Song", artist: "Artist", year: 2025}

  """

  @doc """
  Converts provider-specific track data to a Track struct.

  ## Parameters

    * `data` - Provider-specific track data (e.g., Spotify.Track struct)

  ## Returns

    * `%Track{}` - Standardized track struct

  ## Examples

      iex> Trackable.to_track(spotify_track)
      %Track{title: "Song Title", artist: "Artist Name", year: 1995}

  """
  @spec to_track(any()) :: Songy.Core.Track.t()
  def to_track(data)
end
