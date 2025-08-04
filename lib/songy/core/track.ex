defmodule Songy.Core.Track do
  @moduledoc """
  Represents a musical track in the music year guessing quiz.

  Tracks contain essential metadata about the song including title,
  artist, release year for guessing, cover URL for album artwork,
  and provider-specific metadata for playback functionality.
  """

  use TypedStruct

  @derive {Jason.Encoder, only: [:title, :artist, :year, :cover_url, :meta]}

  typedstruct do
    field :title, String.t(), enforce: true
    field :artist, String.t(), enforce: true
    field :year, pos_integer(), enforce: true
    field :cover_url, String.t()
    field :meta, map(), default: %{}
  end

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
      iex> Track.new(title: "Bohemian Rhapsody", artist: "Queen", year: 1975)
      %Track{title: "Bohemian Rhapsody", artist: "Queen", year: 1975, meta: %{}}

      iex> Track.new(title: "Another One Bites the Dust", artist: "Queen", year: 1980, cover_url: "https://i.scdn.co/image/example")
      %Track{title: "Another One Bites the Dust", artist: "Queen", year: 1980, cover_url: "https://i.scdn.co/image/example", meta: %{}}

      iex> Track.new(title: "Hotel California", artist: "Eagles", year: 1976, meta: %{uri: "spotify:track:40riOy7x9W7GXjyGp4pjAv"})
      %Track{title: "Hotel California", artist: "Eagles", year: 1976, meta: %{uri: "spotify:track:40riOy7x9W7GXjyGp4pjAv"}}
  """
  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, attrs)
  end
end
