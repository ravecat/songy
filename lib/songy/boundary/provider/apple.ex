defmodule Songy.Boundary.Provider.Apple do
  @moduledoc """
  Boundary module for Apple Music functionality.

  Provides search functionality using Apple Music API with Developer Token authentication.
  Unlike Spotify, Apple Music uses a shared Developer Token configured at application level.
  """

  require Logger

  alias Songy.Core.Track

  @base_url "https://api.music.apple.com/v1"
  @storefront "us"
  @types "songs"
  @limit 25

  @doc """
  Returns Developer Token from application config.

  Token is valid for up to 6 months and manually updated via environment variable.
  Configured via APPLE_MUSIC_ACCESS_TOKEN in runtime.exs.

  ## Returns

    * `{:ok, token}` - Valid non-empty token
    * `{:error, :invalid_credentials}` - Token is missing, nil, or empty string

  """
  @spec access_token() :: {:ok, String.t()} | {:error, :invalid_credentials}
  def access_token do
    with {:ok, config} <- Application.fetch_env(:songy, :apple),
         token when is_binary(token) and token != "" <- config[:access_token] do
      {:ok, token}
    else
      _ -> {:error, :invalid_credentials}
    end
  end

  @doc """
  Performs a general search on Apple Music catalog.

  This function searches for tracks, albums, artists, playlists, and other content types
  supported by the Apple Music API.

  ## Parameters

    * `token` - Apple Music Developer Token (required)
    * `params` - Search parameters as keyword list:
      * `:term` - Search query string (required)
      * `:types` - Type of content to search ("songs", "albums", "artists", "playlists")
      * `:limit` - Number of results to return (1-25, default: 5)
      * `:offset` - The index of the first result to return (default: 0)
      * `:storefront` - ISO 3166-1 alpha-2 country code (default: "us")

  ## Returns

    * `{:ok, result}` - Search results as returned by Apple Music API
    * `{:error, :search_failed}` - Apple Music API error

  ## Examples

      # Search for tracks
      search("developer_token_jwt", term: "bohemian rhapsody", types: "songs", limit: 10)

      # Search for albums in specific storefront
      search("developer_token_jwt", term: "abbey road", types: "albums", storefront: "gb")

  """
  @spec search(String.t(), keyword()) :: {:ok, map()} | {:error, :search_failed}
  def search(token, params \\ []) when is_binary(token) do
    result = make_search_request(token, params)
    Logger.debug("Apple Music API request result: #{inspect(result)}")

    case result do
      {:ok, %{status: 200, body: %{"results" => results}}} ->
        Logger.info("Apple Music API search successful: #{length(results)} results")
        {:ok, results}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("Apple Music API error #{status}: #{inspect(body)}")
        {:error, :search_failed}

      {:error, exception} ->
        Logger.error("HTTP request failed: #{inspect(exception)}")
        {:error, :search_failed}
    end
  end

  @doc """
  Searches for a random track in Apple Music catalog.

  ## Parameters

    * `token` - Apple Music Developer Token (required)

  ## Returns

    * `{:ok, track}` - Apple Music Track.Apple struct
    * `{:error, :search_failed}` - Apple Music API error (propagated from `search/2`)
    * `{:error, :no_tracks_found}` - No tracks found for the random query or unexpected response shape

  ## Examples

      Songy.Boundary.Provider.Apple.search_random_track("developer_token_jwt")
      # => {:ok, %Track.Apple{id: "1613600188", attributes: %{"name" => "Entropy", ...}}}

  """
  @spec search_random_track() ::
          {:ok, Track.Apple.t()} | {:error, :invalid_credentials | :search_failed | :no_tracks_found}
  def search_random_track do
    params = random_track_search_params()

    with {:ok, token} <- access_token(),
         {:ok, %{"songs" => %{"data" => [_ | _] = data}}} <- search(token, params) do
      track =
        data
        |> Enum.at(rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(1)), length(data)))
        |> Track.Apple.to_struct()

      Logger.info("Successfully found random track #{inspect(track)} with params: #{inspect(params)}")

      {:ok, track}
    else
      {:ok, %{"songs" => %{"data" => []}}} ->
        Logger.warning("No tracks found for params: #{inspect(random_track_search_params())}")
        {:error, :no_tracks_found}

      {:ok, _other} ->
        Logger.warning("Unexpected response structure for random track search")
        {:error, :no_tracks_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp make_search_request(token, params) do
    {storefront, search_params} = Keyword.pop(params, :storefront, @storefront)

    Req.get("#{@base_url}/catalog/#{storefront}/search",
      headers: [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ],
      params: search_params
    )
  end

  defp random_track_search_params do
    [
      types: @types,
      term: random_query(),
      offset: random_offset(),
      limit: @limit
    ]
  end

  defp random_query, do: <<?a + rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(1)), 26)>> <> "*"

  defp random_offset, do: rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(2)), 1000)
end
