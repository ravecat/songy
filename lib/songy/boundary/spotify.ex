defmodule Songy.Boundary.Spotify do
  @moduledoc """
  Boundary module for Spotify-related functionality in the Songy application.

  This module provides functions to interact with Spotify's API, including
  managing playback, searching for tracks, and handling user authentication.
  """

  require Logger

  @spec transfer_playback(credentials :: Spotify.Credentials.t() | map(), payload :: map()) ::
          {:ok, :playback_transferred} | {:error, :invalid_credentials | :no_device_id | :playback_transfer_failed}
  def transfer_playback(credentials, %{"device_id" => device_id}) do
    with {:ok, credentials} <- ensure_credentials(credentials),
         :ok <- Spotify.Player.transfer_playback(credentials, [device_id]) do
      Logger.info("Successfully transferred playback to device #{device_id}")
      {:ok, :playback_transferred}
    else
      {:error, :invalid_credentials} ->
        {:error, :invalid_credentials}

      {:error, reason} ->
        Logger.warning("Failed to transfer playback to device #{device_id}: #{inspect(reason)}")
        {:error, :playback_transfer_failed}
    end
  end

  def transfer_playback(_, _), do: {:error, :no_device_id}

  @spec start_playback(credentials :: Spotify.Credentials.t() | map(), params :: keyword()) ::
          {:ok, :playback_started} | {:error, :invalid_credentials | :playback_start_failed}
  def start_playback(credentials, params \\ []) do
    with {:ok, credentials} <- ensure_credentials(credentials),
         :ok <- Spotify.Player.play(credentials, params) do
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

  @spec pause_playback(credentials :: Spotify.Credentials.t() | map(), params :: keyword()) ::
          {:ok, :playback_paused} | {:error, :invalid_credentials | :playback_pause_failed}
  def pause_playback(credentials, params \\ []) do
    with {:ok, credentials} <- ensure_credentials(credentials),
         :ok <- Spotify.Player.pause(credentials, params) do
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
  @spec search(credentials :: Spotify.Credentials.t() | map(), params :: keyword()) ::
          {:ok, map()} | {:error, :invalid_credentials | :search_failed}
  def search(credentials, params \\ []) do
    with {:ok, credentials} <- ensure_credentials(credentials),
         {:ok, result} <- Spotify.Search.query(credentials, params) do
      Logger.info("Successfully performed search with query: #{params[:q]}")
      {:ok, result}
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
  @spec search_random_track(credentials :: Spotify.Credentials.t() | map()) ::
          {:ok, map()} | {:error, :invalid_credentials | :search_failed | :no_tracks_found}
  def search_random_track(credentials) do
    params = build_random_track_search_params()

    case search(credentials, params) do
      {:ok, %{items: [track | _]}} ->
        Logger.info("Successfully found random track with query: #{params[:q]}, offset: #{params[:offset]}")
        {:ok, track}

      {:ok, %{items: []}} ->
        Logger.warning("No tracks found for query: #{params[:q]}, offset: #{params[:offset]}")
        {:error, :no_tracks_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_random_track_search_params do
    query = generate_random_track_query()
    offset = generate_random_offset()

    [
      q: query,
      type: "track",
      limit: 1,
      offset: offset
    ]
  end

  defp generate_random_track_query do
    current_year = Date.utc_today().year
    random_letter = generate_random_latin_letter()

    # Generate random year range between 1900 and current year
    start_year = :rand.uniform(current_year - 1900 + 1) + 1900 - 1
    end_year = :rand.uniform(current_year - start_year + 1) + start_year - 1

    "*#{random_letter}* year:#{start_year}-#{end_year}"
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

  defp ensure_credentials(%{access_token: access_token} = params) when is_map(params) and is_binary(access_token) do
    credentials = struct(Spotify.Credentials, params)

    {:ok, credentials}
  end

  defp ensure_credentials(_), do: {:error, :invalid_credentials}
end
