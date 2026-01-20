defimpl Songy.Core.Trackable, for: Songy.Core.Track.Apple do
  @moduledoc """
  Implements the Trackable protocol for Apple Music tracks.

  Transforms Apple Music API track structure into standardized Track format.
  """

  @doc """
  Transforms an Apple Music track struct to Track struct.

  Extracts and maps the following fields:
  - title: Mapped from attributes.name
  - artist: Mapped from attributes.artistName
  - year: Extracted from attributes.releaseDate (YYYY-MM-DD format)
  - cover_url: Artwork URL from attributes.artwork.url with size placeholders replaced
  - meta: Apple Music-specific metadata (preview_url if available)

  ## Examples

      iex> track = %Songy.Core.Track.Apple{
      ...>   id: "1440783454",
      ...>   type: "songs",
      ...>   href: "/v1/catalog/us/songs/1440783454",
      ...>   attributes: %{
      ...>     "name" => "Firestarter",
      ...>     "artistName" => "The Prodigy",
      ...>     "albumName" => "The Fat of the Land",
      ...>     "releaseDate" => "1996-06-30",
      ...>     "artwork" => %{
      ...>       "url" => "https://is1-ssl.mzstatic.com/image/thumb/Music/{w}x{h}bb.jpg"
      ...>     },
      ...>     "previews" => [%{"url" => "https://audio-ssl.itunes.apple.com/preview.m4a"}]
      ...>   }
      ...> }
      iex> Trackable.to_track(track)
      %Track{
        title: "Firestarter",
        artist: "The Prodigy",
        year: 1996,
        cover_url: "https://is1-ssl.mzstatic.com/image/thumb/Music/640x640bb.jpg",
        meta: %{preview_url: "https://audio-ssl.itunes.apple.com/preview.m4a"}
      }

  """
  def to_track(%Songy.Core.Track.Apple{} = track) do
    Songy.Core.Track.new(
      title: title(track),
      artist: artist(track),
      year: year(track),
      cover_url: cover_url(track),
      meta: meta(track)
    )
  end

  defp title(%Songy.Core.Track.Apple{attributes: %{"name" => name}}) when is_binary(name) and name != "",
    do: name

  defp title(_), do: nil

  defp artist(%Songy.Core.Track.Apple{attributes: %{"artistName" => artist}}) when is_binary(artist) and artist != "",
    do: artist

  defp artist(_), do: nil

  defp year(%Songy.Core.Track.Apple{attributes: %{"releaseDate" => date}})
       when is_binary(date) do
    with [year_str | _] <- String.split(date, "-"),
         {year, ""} <- Integer.parse(year_str) do
      year
    else
      _ -> nil
    end
  end

  defp year(_), do: nil

  defp cover_url(%Songy.Core.Track.Apple{
         attributes: %{"artwork" => %{"url" => url}}
       })
       when is_binary(url) do
    String.replace(url, "{w}x{h}", "640x640")
  end

  defp cover_url(_), do: nil

  defp meta(%Songy.Core.Track.Apple{
         attributes: %{"previews" => [%{"url" => url} | _]}
       })
       when is_binary(url) and url != "" do
    %{preview_url: url}
  end

  defp meta(_), do: %{}
end
