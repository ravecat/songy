defmodule Songy.Boundary.Spotify do
  @moduledoc """
  Boundary module for Spotify-related functionality in the Songy application.

  This module provides functions to interact with Spotify's API, including
  managing playback, searching for tracks, and handling user authentication.
  """

  alias Songy.Core.Provider

  require Logger

  @spec authenticate(Plug.Conn.t() | term(), map()) ::
          {:ok, Provider.Spotify.t()} | {:error, term()}
  def authenticate(conn_or_credentials, params) do
    case Spotify.Authentication.authenticate(conn_or_credentials, params) do
      {:ok, credentials} ->
        result =
          credentials
          |> Map.from_struct()
          |> Provider.Spotify.new()

        {:ok, result}

      {:error, reason} ->
        Logger.error("Failed to authenticate with Spotify: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Ensures that Spotify credentials are fresh and valid.

  This function checks if the provided credentials need refreshing based on their
  expiration time, and automatically refreshes them if necessary.

  ## Parameters

    * `credentials` - Provider.Spotify struct containing Spotify credentials

  ## Returns

    * `{:ok, updated_credentials}` - Fresh Provider.Spotify credentials (either original or refreshed)
    * `{:error, reason}` - Failed to refresh or invalid credentials

  """
  @spec ensure_provider_data(Provider.Spotify.t()) :: {:ok, Provider.Spotify.t()} | {:error, term()}
  def ensure_provider_data(%Provider.Spotify{access_token: access_token, refresh_token: refresh_token} = data) do
    with true <- refresh_token?(data),
         spotify_creds <- Spotify.Credentials.new(access_token, refresh_token),
         {:ok, new_data} <- Spotify.Authentication.refresh(spotify_creds) do
      Logger.info("Spotify refresh response #{inspect(new_data)}")

      {:ok, Provider.Spotify.update(data, Map.from_struct(new_data))}
    else
      false ->
        {:ok, data}

      {:error, reason} ->
        Logger.error("Failed to refresh Spotify data: #{inspect(reason)}")
        {:error, reason}

      error ->
        Logger.error("Unexpected response from Spotify API: #{inspect(error)}")
        {:error, :authentication_failed}
    end
  end

  def ensure_provider_data(_), do: {:error, :invalid_credentials}

  @spec start_playback(credentials :: Provider.Spotify.t() | map(), params :: keyword()) ::
          {:ok, :playback_started} | {:error, :invalid_credentials | :playback_start_failed}
  def start_playback(credentials, params \\ []) do
    with {:ok, credentials} <- ensure_credentials(credentials),
         response <- Spotify.Player.play(credentials, params),
         {:ok, _} <- handle_api_response(response) do
      Logger.info("Successfully started playback with options: #{inspect(params)}")
      {:ok, :playback_started}
    else
      {:error, :invalid_credentials} ->
        {:error, :invalid_credentials}

      {:error, reason} ->
        Logger.warning("Spotify API failed to start playback: #{inspect(reason)}")
        {:error, :playback_start_failed}
    end
  end

  @spec pause_playback(credentials :: Provider.Spotify.t() | map(), params :: keyword()) ::
          {:ok, :playback_paused} | {:error, :invalid_credentials | :playback_pause_failed}
  def pause_playback(credentials, params \\ []) do
    with {:ok, credentials} <- ensure_credentials(credentials),
         response <- Spotify.Player.pause(credentials, params),
         {:ok, _} <- handle_api_response(response) do
      Logger.info("Successfully paused playback with options: #{inspect(params)}")
      {:ok, :playback_paused}
    else
      {:error, :invalid_credentials} ->
        {:error, :invalid_credentials}

      {:error, reason} ->
        Logger.warning("Spotify API failed to pause playback: #{inspect(reason)}")
        {:error, :playback_pause_failed}
    end
  end

  @doc """
  Performs a general search on Spotify.

  This function can search for tracks, albums, artists, playlists, and other content types
  supported by the Spotify Web API.

  ## Parameters

    * `credentials` - Spotify credentials with access token or map with :access_token key
    * `params` - Search parameters as keyword list:
      * `:q` - Search query string (required for meaningful results)
      * `:type` - Type of content to search ("track", "album", "artist", "playlist")
      * `:limit` - Number of results to return (1-50, default depends on Spotify API)
      * `:offset` - The index of the first result to return (default: 0)
      * `:market` - ISO 3166-1 alpha-2 country code to limit results

  ## Returns

    * `{:ok, result}` - Search results as returned by Spotify API
    * `{:error, :invalid_credentials}` - Missing or invalid credentials
    * `{:error, :search_failed}` - Spotify API error

  ## Examples

      # Search for tracks
      search(credentials, q: "bohemian rhapsody", type: "track", limit: 10)

      # Search for albums
      search(credentials, q: "dark side of the moon", type: "album")

      # Search for artists
      search(credentials, q: "queen", type: "artist", limit: 5)

  """
  @spec search(credentials :: Provider.Spotify.t() | map(), params :: keyword()) ::
          {:ok, map()} | {:error, :invalid_credentials | :search_failed}
  def search(credentials, params \\ []) do
    with {:ok, credentials} <- ensure_credentials(credentials),
         response <- Spotify.Search.query(credentials, params) do
      Logger.info("Spotify API response: #{inspect(response)}")

      case handle_api_response(response) do
        {:ok, result} ->
          Logger.info("Successfully performed search with params: #{inspect(params)}")
          {:ok, result}

        {:error, reason} = error ->
          Logger.error("Spotify search failed: #{inspect(reason)}")
          error
      end
    else
      {:error, :invalid_credentials} ->
        {:error, :invalid_credentials}

      {:error, reason} ->
        Logger.warning("Failed to perform search: #{inspect(reason)}")
        {:error, :search_failed}
    end
  end

  @doc """
  Searches for a random track on Spotify.

  This function generates a random search query using a random letter and year range,
  then returns the first track found. It's designed for music discovery and quiz games.

  ## Parameters

    * `credentials` - Spotify credentials with access token or map with :access_token key

  ## Returns

    * `{:ok, track}` - A single track map as returned by Spotify API
    * `{:error, :invalid_credentials}` - Missing or invalid credentials
    * `{:error, :search_failed}` - Spotify API error
    * `{:error, :no_tracks_found}` - No tracks found for the random query

  ## Implementation Details

  The function uses the general `search/2` function with randomly generated parameters:
  - Random letter (a-z, A-Z) with wildcard: "*a*", "*B*", etc.
  - Random year range between 1900 and current year: "year:1950-1965"
  - Random offset (0-999) to get different results
  - Limited to 1 track result

  """
  @spec search_random_track(credentials :: Provider.Spotify.t() | map()) ::
          {:ok, map()} | {:error, :invalid_credentials | :search_failed | :no_tracks_found}
  def search_random_track(credentials) do
    params = build_random_track_search_params()

    case search(credentials, params) do
      {:ok, %{items: [track | _]}} ->
        Logger.info("Successfully found random track #{inspect(track)} with query: #{inspect(params)}")
        {:ok, track}

      {:ok, %{items: []}} ->
        Logger.warning("No tracks found for query: #{inspect(params)}")
        {:error, :no_tracks_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # That search params return a random track result in most cases. Change carefully if needed.
  defp build_random_track_search_params do
    :rand.seed(:exsss, :os.system_time(:nanosecond))

    query = generate_random_track_query()
    offset = generate_random_offset()

    [
      q: query,
      type: "track",
      limit: 2,
      offset: offset
    ]
  end

  defp generate_random_track_query do
    random_letter = generate_random_latin_letter()
    {start_year, end_year} = generate_random_time_range()

    "#{random_letter} year:#{start_year}-#{end_year}"
  end

  defp generate_random_time_range do
    current_year = Date.utc_today().year
    start_year = :rand.uniform(current_year - 1900 + 1) + 1900 - 1
    end_year = :rand.uniform(current_year - start_year + 1) + start_year - 1

    {start_year, end_year}
  end

  defp generate_random_latin_letter do
    letter_index = :rand.uniform(52)

    codepoint =
      if letter_index <= 26 do
        # Lowercase: ?a (97) to ?z (122)
        ?a + letter_index - 1
      else
        # Uppercase: ?A (65) to ?Z (90)
        ?A + letter_index - 26 - 1
      end

    <<codepoint>>
  end

  defp generate_random_offset do
    :rand.uniform(1000) - 1
  end

  defp ensure_credentials(%Spotify.Credentials{} = credentials), do: {:ok, credentials}

  defp ensure_credentials(%{access_token: access_token} = params) when is_struct(params) and is_binary(access_token) do
    ensure_credentials(Map.from_struct(params))
  end

  defp ensure_credentials(%{access_token: access_token} = params) when is_binary(access_token) do
    credentials = struct(Spotify.Credentials, params)

    {:ok, credentials}
  end

  defp ensure_credentials(_), do: {:error, :invalid_credentials}

  defp handle_api_response({:error, reason}), do: {:error, reason}
  defp handle_api_response({:ok, %{"error" => %{"message" => reason}}}), do: {:error, reason}
  defp handle_api_response({:ok, %{"error" => reason}}) when is_binary(reason), do: {:error, reason}
  defp handle_api_response({:ok, result}), do: {:ok, result}
  defp handle_api_response(:ok), do: {:ok, :ok}
  defp handle_api_response(result), do: {:ok, result}

  defp refresh_token?(credentials) do
    case Map.get(credentials, :expires_at) do
      nil -> true
      expires_at -> DateTime.compare(expires_at, DateTime.utc_now()) == :lt
    end
  end
end
