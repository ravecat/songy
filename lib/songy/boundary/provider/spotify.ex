defmodule Songy.Boundary.Provider.Spotify do
  @moduledoc """
  Boundary module for Spotify-related functionality in the Songy application.

  This module provides functions to interact with Spotify's API, including
  managing playback, searching for tracks, and handling user authentication.
  """

  alias Songy.Core.Provider
  alias Songy.Core.Track
  alias Songy.Core.Trackable

  use Songy.Boundary.Provider

  require Logger

  @impl true
  def ensure(%Provider.Spotify{access_token: access_token, refresh_token: refresh_token} = provider) do
    with true <- refresh_token?(provider),
         credentials <- Spotify.Credentials.new(access_token, refresh_token),
         {:ok, refreshed_provider} <- Spotify.Authentication.refresh(credentials) do
      Logger.info("Spotify refresh response #{inspect(refreshed_provider)}")

      {:ok, :spotify, Provider.Spotify.update(provider, %{access_token: refreshed_provider.access_token})}
    else
      false ->
        {:ok, :spotify, provider}

      {:error, reason} ->
        Logger.error("Failed to refresh Spotify data: #{inspect(reason)}")
        {:error, reason}

      error ->
        Logger.error("Unexpected response from Spotify API: #{inspect(error)}")
        {:error, :authentication_failed}
    end
  end

  def ensure(_), do: {:error, :invalid_credentials}

  @impl true
  def start_playback(%{device_id: device_id} = provider, %Track{meta: %{uri: uri}}) do
    params = [uris: [uri], device_id: device_id]

    with {:ok, credentials} <- ensure_credentials(provider),
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

  def start_playback(_provider, %Track{}) do
    {:error, :missing_track_uri}
  end

  @impl true
  def pause_playback(provider) do
    with {:ok, credentials} <- ensure_credentials(provider),
         response <- Spotify.Player.pause(credentials, []),
         {:ok, _} <- handle_api_response(response) do
      Logger.info("Successfully paused playback with options: []")
      {:ok, :playback_paused}
    else
      {:error, :invalid_credentials} ->
        {:error, :invalid_credentials}

      {:error, reason} ->
        Logger.warning("Spotify API failed to pause playback: #{inspect(reason)}")
        {:error, :playback_pause_failed}
    end
  end

  def search(credentials) do
    search(credentials, [])
  end

  @impl true
  def search(%Provider.Spotify{} = provider, params) do
    with {:ok, credentials} <- ensure_credentials(provider),
         response <- Spotify.Search.query(credentials, params),
         {:ok, %{items: items}} <- handle_api_response(response) do
      Logger.info("Successfully performed search with params: #{inspect(params)}")
      {:ok, Enum.map(items, &Trackable.to_track/1)}
    else
      {:error, :invalid_credentials} ->
        {:error, :invalid_credentials}

      {:error, reason} ->
        Logger.warning("Failed to perform search: #{inspect(reason)}")
        {:error, :search_failed}
    end
  end

  def search(credentials, params) do
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

  @impl true
  def search_random_track(%Provider.Spotify{} = provider) do
    params = build_random_track_search_params()

    with {:ok, credentials} <- ensure_credentials(provider),
         response <- Spotify.Search.query(credentials, params),
         {:ok, %{items: [track | _]}} <- handle_api_response(response) do
      Logger.info("Successfully found random track #{inspect(track)} with query: #{inspect(params)}")
      {:ok, Trackable.to_track(track)}
    else
      {:ok, %{items: []}} ->
        Logger.warning("No tracks found for query: #{inspect(params)}")
        {:error, :no_tracks_found}

      {:error, :invalid_credentials} ->
        {:error, :invalid_credentials}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def search_random_track(credentials) do
    search_random_track_api(credentials)
  end

  @spec authenticate(Plug.Conn.t() | Spotify.Credentials.t(), map()) ::
          {:ok, Provider.Spotify.t()} | {:error, term()}
  def authenticate(conn_or_credentials, params) do
    with {:ok, credentials} <- get_credentials(conn_or_credentials),
         {:ok, new_credentials} <- Spotify.Authentication.authenticate(credentials, params),
         result <- new_credentials |> Map.from_struct() |> Provider.Spotify.new() do
      {:ok, result}
    else
      {:error, :invalid_credentials} ->
        Logger.error("Invalid credentials provided to authenticate")
        {:error, :invalid_credentials}

      {:error, reason} ->
        Logger.error("Failed to authenticate with Spotify: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_credentials(%Plug.Conn{} = conn), do: {:ok, Spotify.Credentials.new(conn)}
  defp get_credentials(%Spotify.Credentials{} = creds), do: {:ok, creds}
  defp get_credentials(_), do: {:error, :invalid_credentials}

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
  @spec search_random_track_api(credentials :: Provider.Spotify.t() | map()) ::
          {:ok, map()} | {:error, :invalid_credentials | :search_failed | :no_tracks_found}
  def search_random_track_api(credentials) do
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
    start_year = Enum.random(1900..current_year)
    end_year = Enum.random(start_year..current_year)

    {start_year, end_year}
  end

  defp generate_random_latin_letter do
    index = rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(1)), 52)
    codepoint = if index < 26, do: ?a + index, else: ?A + (index - 26)
    <<codepoint>>
  end

  defp generate_random_offset do
    rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(2)), 1000)
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
