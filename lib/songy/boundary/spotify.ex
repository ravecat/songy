defmodule Songy.Boundary.Spotify do
  @moduledoc """
  Boundary module for Spotify-related functionality in the Songy application.

  This module provides functions to interact with Spotify's API, including
  managing playback, searching for tracks, and handling user authentication.
  """
  alias Songy.Core.Provider

  require Logger

  @spec transfer_playback(provider :: Provider.t(), payload :: map()) ::
          {:ok, :transferred} | {:error, :no_credentials | :invalid_provider | :no_device_id | :transfer_failed}
  def transfer_playback(provider, %{"device_id" => device_id}) do
    with {:ok, provider} <- validate_provider(provider),
         {:ok, credentials} <- extract_credentials(provider),
         :ok <- Spotify.Player.transfer_playback(credentials, [device_id]) do
      Logger.info("Successfully transferred playback to device #{device_id}")
      {:ok, :transferred}
    else
      {:error, reason} when reason in [:no_credentials, :invalid_provider] ->
        {:error, reason}

      {:error, reason} ->
        Logger.warning("Failed to transfer playback to device #{device_id}: #{inspect(reason)}")
        {:error, :transfer_failed}
    end
  end

  def transfer_playback(_, _), do: {:error, :no_device_id}

  @spec start_playback(provider :: Provider.t(), params :: keyword()) ::
          {:ok, :playback_started} | {:error, :no_credentials | :invalid_provider | :playback_start_failed}
  def start_playback(provider, params \\ []) do
    with {:ok, provider} <- validate_provider(provider),
         {:ok, credentials} <- extract_credentials(provider),
         :ok <- Spotify.Player.play(credentials, params) do
      Logger.info("Successfully started playback with options: #{inspect(params)}")
      {:ok, :playback_started}
    else
      {:error, reason} when reason in [:no_credentials, :invalid_provider] ->
        {:error, reason}

      {:error, reason} ->
        Logger.warning("Spotify API failed to start playback: #{inspect(reason)}")
        {:error, :playback_start_failed}
    end
  end

  @spec pause_playback(provider :: Provider.t(), params :: keyword()) ::
          {:ok, :playback_paused} | {:error, :no_credentials | :invalid_provider | :playback_pause_failed}
  def pause_playback(provider, params \\ []) do
    with {:ok, provider} <- validate_provider(provider),
         {:ok, credentials} <- extract_credentials(provider),
         :ok <- Spotify.Player.pause(credentials, params) do
      Logger.info("Successfully paused playback with options: #{inspect(params)}")
      {:ok, :playback_paused}
    else
      {:error, reason} when reason in [:no_credentials, :invalid_provider] ->
        {:error, reason}

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

    * `provider` - A validated Spotify provider with access token
    * `params` - Search parameters as keyword list:
      * `:q` - Search query string (required for meaningful results)
      * `:type` - Type of content to search ("track", "album", "artist", "playlist")
      * `:limit` - Number of results to return (1-50, default depends on Spotify API)
      * `:offset` - The index of the first result to return (default: 0)
      * `:market` - ISO 3166-1 alpha-2 country code to limit results

  ## Returns

    * `{:ok, result}` - Search results as returned by Spotify API
    * `{:error, :no_credentials}` - Provider missing access token
    * `{:error, :invalid_provider}` - Provider is not Spotify
    * `{:error, :search_failed}` - Spotify API error

  ## Examples

      # Search for tracks
      search(provider, q: "bohemian rhapsody", type: "track", limit: 10)

      # Search for albums
      search(provider, q: "dark side of the moon", type: "album")

      # Search for artists
      search(provider, q: "queen", type: "artist", limit: 5)

  """
  @spec search(provider :: Provider.t(), params :: keyword()) ::
          {:ok, map()} | {:error, :no_credentials | :invalid_provider | :search_failed}
  def search(provider, params \\ []) do
    with {:ok, provider} <- validate_provider(provider),
         {:ok, credentials} <- extract_credentials(provider) do
      case Spotify.Search.query(credentials, params) do
        {:ok, result} ->
          Logger.info("Successfully performed search with query: #{params[:q]}")
          {:ok, result}

        {:error, reason} ->
          Logger.warning("Failed to perform search: #{inspect(reason)}")
          {:error, :search_failed}
      end
    end
  end

  @doc """
  Searches for a random track on Spotify.

  This function generates a random search query using a random letter and year range,
  then returns the first track found. It's designed for music discovery and quiz games.

  ## Parameters

    * `provider` - A validated Spotify provider with access token

  ## Returns

    * `{:ok, track}` - A single track map as returned by Spotify API
    * `{:error, :no_credentials}` - Provider missing access token
    * `{:error, :invalid_provider}` - Provider is not Spotify
    * `{:error, :search_failed}` - Spotify API error
    * `{:error, :no_tracks_found}` - No tracks found for the random query

  ## Implementation Details

  The function uses the general `search/2` function with randomly generated parameters:
  - Random letter (a-z, A-Z) with wildcard: "*a*", "*B*", etc.
  - Random year range between 1900 and current year: "year:1950-1965"
  - Random offset (0-999) to get different results
  - Limited to 1 track result

  """
  @spec search_random_track(provider :: Provider.t()) ::
          {:ok, map()} | {:error, :no_credentials | :invalid_provider | :search_failed | :no_tracks_found}
  def search_random_track(provider) do
    params = build_random_track_search_params()

    case search(provider, params) do
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

  defp validate_provider(%{id: :spotify} = provider), do: {:ok, provider}
  defp validate_provider(_), do: {:error, :invalid_provider}

  defp extract_credentials(%{meta: %{access_token: token}}) when not is_nil(token) do
    credentials = struct(Spotify.Credentials, %{access_token: token})
    {:ok, credentials}
  end

  defp extract_credentials(_), do: {:error, :no_credentials}
end
