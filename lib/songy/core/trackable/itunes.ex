defimpl Songy.Core.Trackable, for: Songy.Core.Track.ITunes do
  @moduledoc """
  Implements the Trackable protocol for iTunes Search API tracks.

  Transforms iTunes track structure into standardized Track format.
  """

  @doc """
  Transforms an iTunes track struct to Track struct.

  Extracts and maps the following fields:
  - title: Mapped from trackName
  - artist: Mapped from artistName
  - year: Extracted from releaseDate (YYYY-MM-DDTHH:MM:SSZ format)
  - cover_url: Artwork URL from artworkUrl100 (with size normalized)
  - meta: iTunes-specific metadata (previewUrl if available)

  ## Examples

      iex> track = %Songy.Core.Track.ITunes{
      ...>   trackName: "Bohemian Rhapsody",
      ...>   artistName: "Queen",
      ...>   releaseDate: "1975-10-31T12:00:00Z",
      ...>   artworkUrl100: "https://is1-ssl.mzstatic.com/image/thumb/Music/100x100bb.jpg",
      ...>   previewUrl: "https://audio-ssl.itunes.apple.com/preview.m4a"
      ...> }
      iex> Trackable.to_track(track)
      %Track{
        title: "Bohemian Rhapsody",
        artist: "Queen",
        year: 1975,
        cover_url: "https://is1-ssl.mzstatic.com/image/thumb/Music/640x640bb.jpg",
        meta: %{preview_url: "https://audio-ssl.itunes.apple.com/preview.m4a"}
      }

  """
  def to_track(%Songy.Core.Track.ITunes{} = track) do
    Songy.Core.Track.new(
      title: title(track),
      artist: artist(track),
      year: year(track),
      cover_url: cover_url(track),
      meta: meta(track)
    )
  end

  defp title(%Songy.Core.Track.ITunes{trackName: name}) when is_binary(name) and name != "", do: name
  defp title(_), do: nil

  defp artist(%Songy.Core.Track.ITunes{artistName: artist}) when is_binary(artist) and artist != "", do: artist
  defp artist(_), do: nil

  defp year(%Songy.Core.Track.ITunes{releaseDate: date}) when is_binary(date) do
    with [year_str | _] <- String.split(date, "-"),
         {year, ""} <- Integer.parse(year_str) do
      year
    else
      _ -> nil
    end
  end

  defp year(_), do: nil

  defp cover_url(%Songy.Core.Track.ITunes{} = track) do
    track.artworkUrl100
    |> fallback_artwork_url(track.artworkUrl60)
    |> fallback_artwork_url(track.artworkUrl30)
    |> normalize_artwork_url()
  end

  defp fallback_artwork_url(url, _fallback) when is_binary(url) and url != "", do: url
  defp fallback_artwork_url(_, fallback), do: fallback

  defp normalize_artwork_url(url) when is_binary(url) and url != "" do
    Regex.replace(~r/\d+x\d+bb/, url, "640x640bb")
  end

  defp normalize_artwork_url(_), do: nil

  defp meta(%Songy.Core.Track.ITunes{previewUrl: url}) when is_binary(url) and url != "" do
    %{preview_url: url}
  end

  defp meta(_), do: %{}
end
