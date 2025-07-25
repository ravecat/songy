defmodule Songy.Core.Track do
  @moduledoc """
  Represents a musical track in the music year guessing quiz.

  Tracks contain essential metadata about the song including title,
  artist, release year for guessing, and cover URL for album artwork.
  """

  use TypedStruct

  @derive {Jason.Encoder, only: [:title, :artist, :year, :cover_url]}

  typedstruct do
    field :title, String.t(), enforce: true
    field :artist, String.t(), enforce: true
    field :year, pos_integer(), enforce: true
    field :cover_url, String.t()
  end

  @doc """
  Creates a new track with the given attributes.

  ## Parameters
    * `attrs` - Keyword list containing track attributes
      * `:title` - Track title (required)
      * `:artist` - Artist name (required)
      * `:year` - Release year (required)
      * `:cover_url` - URL for album cover image

  ## Examples
      iex> Track.new(title: "Bohemian Rhapsody", artist: "Queen", year: 1975)
      %Track{title: "Bohemian Rhapsody", artist: "Queen", year: 1975}

      iex> Track.new(title: "Another One Bites the Dust", artist: "Queen", year: 1980, cover_url: "https://i.scdn.co/image/example")
      %Track{title: "Another One Bites the Dust", artist: "Queen", year: 1980, cover_url: "https://i.scdn.co/image/example"}
  """
  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, attrs)
  end
end
