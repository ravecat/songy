defmodule Songy.Core.Track do
  @moduledoc """
  Represents a musical track in the music year guessing quiz.

  Tracks contain essential metadata about the song including title,
  artist, release year for guessing, and preview URL for playback.
  """

  use TypedStruct

  @derive {Jason.Encoder, only: [:id, :title, :artist, :year, :preview_url]}

  typedstruct do
    field :id, String.t(), enforce: true
    field :title, String.t(), enforce: true
    field :artist, String.t(), enforce: true
    field :year, pos_integer(), enforce: true
    field :preview_url, String.t()
  end

  @doc """
  Creates a new track with the given attributes.

  ## Parameters
    * `attrs` - Keyword list containing track attributes
      * `:id` - External track ID (required)
      * `:title` - Track title (required)
      * `:artist` - Artist name (required)
      * `:year` - Release year (required)
      * `:preview_url` - URL for audio preview (optional)

  ## Examples
      iex> Track.new(id: "spotify:track:4uLU6hMCjMI75M1A2tKUQC", title: "Bohemian Rhapsody", artist: "Queen", year: 1975)
      %Track{id: "spotify:track:4uLU6hMCjMI75M1A2tKUQC", title: "Bohemian Rhapsody", artist: "Queen", year: 1975}
  """
  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, attrs)
  end
end
