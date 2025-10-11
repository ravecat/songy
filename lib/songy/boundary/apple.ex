defmodule Songy.Boundary.Apple do
  @moduledoc """
  Boundary module for Apple Music functionality.

  Provides search functionality using Apple Music API with Developer Token authentication.
  Unlike Spotify, Apple Music uses a shared Developer Token configured at application level.
  """

  require Logger

  @base_url "https://api.music.apple.com/v1"

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
      * `:storefront` - ISO 3166-1 alpha-2 country code (default from config)

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
    case make_search_request(token, params) do
      {:ok, %{status: 200, body: %{"results" => results}}} ->
        {:ok, results}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("Apple Music API error #{status}: #{inspect(body)}")
        {:error, :search_failed}

      {:error, exception} ->
        Logger.error("HTTP request failed: #{inspect(exception)}")
        {:error, :search_failed}
    end
  end

  defp make_search_request(token, params) do
    {storefront, search_params} = Keyword.pop(params, :storefront, Application.fetch_env!(:songy, :apple)[:storefront])

    Req.get("#{@base_url}/catalog/#{storefront}/search",
      headers: [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ],
      params: search_params
    )
  end
end
