defmodule Songy.Core.Track do
  @moduledoc """
  Represents a musical track in the music year guessing quiz.

  Tracks contain essential metadata about the song including title,
  artist, release year for guessing, cover URL for album artwork,
  and provider-specific metadata for playback functionality.
  """

  use TypedStruct

  @derive {Jason.Encoder, only: [:id, :title, :artist, :year, :cover_url, :meta]}

  @id_size 4

  typedstruct do
    field :id, String.t(), enforce: true
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
      iex> track = Track.new(title: "Another One Bites the Dust", artist: "Queen", year: 1980, cover_url: "https://i.scdn.co/image/example")
      iex> track.title
      "Another One Bites the Dust"

      iex> track = Track.new(title: "Hotel California", artist: "Eagles", year: 1976, meta: %{uri: "spotify:track:40riOy7x9W7GXjyGp4pjAv"})
      iex> track.meta
      %{uri: "spotify:track:40riOy7x9W7GXjyGp4pjAv"}
  """
  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(
      __MODULE__,
      Keyword.merge(
        [id: generate_uuid()],
        attrs
      )
    )
  end

  defp generate_uuid do
    @id_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
