defmodule Songy.Boundary.Provider.ITunes do
  @moduledoc """
  Boundary module for iTunes preview functionality.

  Provides search functionality using the iTunes Search API.
  This API does not require authentication and returns preview URLs when available.
  """

  require Logger

  alias Songy.Core.Track

  @base_url "https://itunes.apple.com"
  @media "music"
  @entity "song"
  @limit 25

  @doc """
  Performs a search on the iTunes Search API.

  This function searches for tracks, albums, artists, playlists, and other content types
  supported by the iTunes Search API.

  ## Parameters

    * `params` - Search parameters as keyword list:
      * `:term` - Search query string (required)
      * `:entity` - Type of content to search ("song", "album", "musicArtist")
      * `:types` - Apple Music-compatible alias for entity ("songs", "albums", "artists")
      * `:limit` - Number of results to return (1-200, default: 5)
      * `:offset` - The index of the first result to return (default: 0)
      * `:country` - ISO 3166-1 alpha-2 country code (default: "us")
      * `:storefront` - Alias for :country

  ## Returns

    * `{:ok, result}` - Search results as returned by iTunes Search API
    * `{:error, :search_failed}` - iTunes Search API error

  ## Examples

      # Search for tracks
      search(term: "bohemian rhapsody", entity: "song", limit: 10)

      # Search for albums in specific country
      search(term: "abbey road", types: "albums", country: "gb")

  """
  @spec search(keyword()) :: {:ok, list()} | {:error, :search_failed}
  def search(params \\ []) when is_list(params) do
    result = make_search_request(params)
    Logger.debug("iTunes Search API request result: #{inspect(result)}")

    case result do
      {:ok, %{status: 200, body: body}} ->
        handle_success_body(body)

      {:ok, %{status: status, body: body}} ->
        Logger.warning("iTunes Search API error #{status}: #{inspect(body)}")
        {:error, :search_failed}

      {:error, exception} ->
        Logger.error("HTTP request failed: #{inspect(exception)}")
        {:error, :search_failed}
    end
  end

  @doc """
  Searches for a random track in iTunes catalog.

  ## Returns

    * `{:ok, track}` - iTunes Track.ITunes struct
    * `{:error, :search_failed}` - iTunes Search API error (propagated from `search/1`)
    * `{:error, :no_tracks_found}` - No tracks found for the random query or unexpected response

  """
  @spec search_random_track() ::
          {:ok, Track.ITunes.t()} | {:error, :search_failed | :no_tracks_found}
  def search_random_track do
    params = random_track_search_params()

    with {:ok, results} when is_list(results) <- search(params),
         [_ | _] = songs <- Enum.filter(results, &song?/1) do
      track =
        songs
        |> Enum.random()
        |> Track.ITunes.to_struct()

      Logger.info("Successfully found random track #{inspect(track)} with params: #{inspect(params)}")

      {:ok, track}
    else
      [] ->
        Logger.warning("No tracks found for params: #{inspect(params)}")
        {:error, :no_tracks_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp make_search_request(params) do
    Req.get("#{@base_url}/search",
      params: params,
      headers: [{"Accept", "application/json"}]
    )
  end

  defp handle_success_body(body) do
    case decode_body(body) do
      {:ok, %{"resultCount" => count, "results" => results}} when is_list(results) ->
        Logger.info("iTunes Search API search successful: #{count} results")
        {:ok, results}

      {:ok, _other} ->
        Logger.warning("iTunes Search API unexpected body: #{inspect(body)}")
        {:error, :search_failed}

      {:error, reason} ->
        Logger.warning("iTunes Search API decode failed: #{inspect(reason)}")
        {:error, :search_failed}
    end
  end

  defp decode_body(body) when is_map(body), do: {:ok, body}

  defp decode_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, error} -> {:error, error}
    end
  end

  defp decode_body(body), do: {:error, {:unexpected_body, body}}

  defp random_track_search_params do
    [
      term: random_query(),
      media: @media,
      entity: @entity,
      offset: random_offset(),
      limit: @limit
    ]
  end

  defp random_query, do: <<:rand.uniform(26) + ?a - 1>> <> "*"

  defp random_offset, do: :rand.uniform(1000) - 1

  defp song?(%{"kind" => "song"}), do: true
  defp song?(%{"wrapperType" => "track", "kind" => "song"}), do: true
  defp song?(_), do: false

end
