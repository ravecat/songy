defmodule Songy.Boundary.Provider.ITunes do
  @moduledoc """
  Boundary module for iTunes preview functionality.

  Provides search functionality using the iTunes Search API.
  This API does not require authentication and returns preview URLs when available.
  """

  require Logger

  @behaviour Songy.Boundary.Provider

  alias Songy.Core.Provider
  alias Songy.Core.Track
  alias Songy.Core.Trackable

  @media "music"
  @entity "song"
  @limit 50
  @attributes ~w(artistTerm albumTerm songTerm)
  @countries ~w(
    us gb de fr jp ru ca au br it es in mx kr nl se pl ch ar at tr be hk
  )
  @headers [
    {"Accept", "application/json"}
  ]

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
      * `:country` - ISO 3166-1 alpha-2 country code (default: "us")

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
        |> Enum.at(rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(2)), length(songs)))
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

  @impl true
  def ensure(_provider) do
    {:ok, :itunes, Provider.ITunes.new()}
  end

  @impl true
  def start_playback(_provider, _track) do
    {:ok, :playback_started}
  end

  @impl true
  def pause_playback(_provider) do
    {:ok, :playback_paused}
  end

  @impl true
  def search_random_track(_provider) do
    case search_random_track() do
      {:ok, track} ->
        {:ok, Trackable.to_track(track)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def search(_provider, params) do
    case search(params) do
      {:ok, results} ->
        tracks =
          results
          |> Enum.filter(&song?/1)
          |> Enum.map(&(Track.ITunes.to_struct(&1) |> Trackable.to_track()))

        {:ok, tracks}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp make_search_request(params) do
    Req.get("#{base_url()}/search",
      params: params,
      headers: @headers
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
      term: random_term(),
      media: @media,
      entity: @entity,
      limit: @limit,
      attribute: random_attribute(),
      country: random_country()
    ]
  end

  defp random_attribute do
    Enum.at(@attributes, rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(1)), length(@attributes)))
  end

  defp random_country do
    Enum.at(@countries, rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(1)), length(@countries)))
  end

  defp random_term do
    if rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(1)), 2) == 0 do
      <<random_letter()>> <> "*"
    else
      <<random_letter(), random_letter()>> <> "*"
    end
  end

  defp random_letter, do: ?a + rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(1)), 26)

  defp song?(%{"wrapperType" => "track", "kind" => "song"}), do: true
  defp song?(%{"kind" => "song"}), do: true
  defp song?(_), do: false

  defp base_url do
    Application.fetch_env!(:songy, :providers)
    |> Keyword.fetch!(:itunes)
    |> Keyword.fetch!(:url)
  end
end
