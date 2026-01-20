defimpl Songy.Core.Trackable, for: Spotify.Track do
  @doc """
  Transforms a Spotify.Track struct to Track struct.

  Extracts and maps the following fields:
  - title: Mapped from Spotify track name
  - artist: All meaningful artist names joined with comma
  - year: Extracted from album release_date
  - cover_url: Album cover image URL from album.images[0].url
  - meta: Spotify-specific metadata for playback

  ## Examples

      iex> track = %Spotify.Track{
      ...>   id: "623rRTKwGmgjH6sjE9uWLh",
      ...>   name: "Scatman (ski-ba-bop-ba-dop-bop)",
      ...>   uri: "spotify:track:623rRTKwGmgjH6sjE9uWLh",
      ...>   artists: [%{"name" => "Scatman John"}, %{"name" => "Featured Artist"}],
      ...>   album: %{
      ...>     "release_date" => "1995-06-01",
      ...>     "images" => [%{"url" => "https://i.scdn.co/image/example"}]
      ...>   },
      ...>   cover_url: "https://i.scdn.co/image/example"
      ...> }
      iex> Trackable.to_track(track)
      %Track{
        title: "Scatman (ski-ba-bop-ba-dop-bop)",
        artist: "Scatman John, Featured Artist",
        year: 1995,
        cover_url: "https://i.scdn.co/image/example",
        meta: %{uri: "spotify:track:623rRTKwGmgjH6sjE9uWLh"}
      }

  """
  def to_track(%Spotify.Track{} = track) do
    Songy.Core.Track.new(
      title: title(track),
      artist: artist(track),
      year: year(track),
      cover_url: cover_url(track),
      meta: meta(track)
    )
  end

  # Extract track title from name field
  defp title(%Spotify.Track{name: name}) when is_binary(name) and name != "", do: name
  defp title(_), do: nil

  # Extract all meaningful artist names from artists array and join with comma
  defp artist(%Spotify.Track{artists: artists}) when is_list(artists) do
    artists
    |> Enum.filter(fn artist -> is_map(artist) and Map.has_key?(artist, "name") end)
    |> Enum.map(fn %{"name" => name} -> name end)
    |> Enum.filter(&(&1 != nil and is_binary(&1) and String.trim(&1) != ""))
    |> case do
      [] -> nil
      names -> Enum.join(names, ", ")
    end
  end

  defp artist(_), do: nil

  # Extract cover URL from album images (first image in array)
  defp cover_url(%Spotify.Track{album: %{"images" => [%{"url" => url} | _]}}) when is_binary(url), do: url
  defp cover_url(_), do: nil

  # Extract release year from album release_date
  defp year(%Spotify.Track{album: %{"release_date" => date}}) when is_binary(date) do
    with [year_str | _] <- String.split(date, "-"),
         {year, ""} <- Integer.parse(year_str) do
      year
    else
      _ -> nil
    end
  end

  defp year(_), do: nil

  # Extract Spotify-specific metadata including URI for playback
  defp meta(%Spotify.Track{uri: uri}) when is_binary(uri) and uri != "" do
    %{uri: uri}
  end

  defp meta(_), do: %{}
end
