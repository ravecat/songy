defmodule Songy.Core.Track do
  @moduledoc """
  Represents a musical track in the music year guessing quiz.

  Tracks contain essential metadata about the song including title,
  artist, release year for guessing, cover URL for album artwork,
  and provider-specific metadata for playback functionality.
  """

  @derive {Jason.Encoder, only: [:id, :title, :artist, :year, :cover_url, :meta]}

  defstruct [
    :id,
    :title,
    :artist,
    :year,
    :cover_url,
    meta: %{}
  ]

  @typedoc "Unique track identifier (base64 encoded)"
  @type id :: String.t()

  @typedoc "Track title"
  @type title :: String.t()

  @typedoc "Artist name"
  @type artist :: String.t()

  @typedoc "Release year for guessing"
  @type year :: pos_integer()

  @typedoc "Album cover image URL"
  @type cover_url :: String.t() | nil

  @typedoc """
  Provider-specific metadata for playback functionality.

  Fields:
    * `:preview_url` - Audio preview URL (30-60 second clips, used by iTunes/Apple Music)
    * `:uri` - Platform-specific URI (e.g., spotify:track:xxx, used by Spotify)
  """
  @type meta :: %{
          optional(:preview_url) => String.t(),
          optional(:uri) => String.t()
        }

  @typedoc "Track structure"
  @type t :: %__MODULE__{
          id: id,
          title: title,
          artist: artist,
          year: year,
          cover_url: cover_url,
          meta: meta
        }

  @doc """
  Creates a new track with the given attributes.

  ## Parameters
    * `attrs` - Keyword list containing track attributes
      * `:title` - Track title (required)
      * `:artist` - Artist name (required)
      * `:year` - Release year (required)
      * `:cover_url` - URL for album cover image
      * `:meta` - Provider-specific metadata map (default: %{})

  ## Examples
      iex> track = Track.new(title: "Another One Bites the Dust", artist: "Queen", year: 1980, cover_url: "https://i.scdn.co/image/example")
      iex> track.title
      "Another One Bites the Dust"

      iex> track = Track.new(title: "Hotel California", artist: "Eagles", year: 1976, meta: %{uri: "spotify:track:40riOy7x9W7GXjyGp4pjAv"})
      iex> track.meta
      %{uri: "spotify:track:40riOy7x9W7GXjyGp4pjAv"}
  """
  @id_size 4

  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(
      __MODULE__,
      Keyword.put(attrs, :id, id())
    )
  end

  @spec id() :: String.t()
  defp id do
    @id_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
