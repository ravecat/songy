defmodule Songy.Boundary.Provider.Spotify do
  @moduledoc """
  Boundary module for Spotify-related functionality in the Songy application.

  This module provides functions to interact with Spotify's API, including
  managing playback, searching for tracks, and handling user authentication.
  """

  alias Songy.Core.Provider
  alias Songy.Core.Track
  alias Songy.Core.Trackable
  alias Spotify.Authentication
  alias Spotify.Credentials
  alias Spotify.Player
  alias Spotify.Search

  use Songy.Boundary.Provider

  require Logger

  @cover_tracks_limit 50

  @impl true
  def ensure(%Provider.Spotify{access_token: access_token, refresh_token: refresh_token} = provider) do
    with true <- Provider.Spotify.refresh?(provider),
         credentials <- Credentials.new(access_token, refresh_token),
         {:ok, refreshed_provider} <- Authentication.refresh(credentials) do
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
         response <- Player.play(credentials, params),
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
         response <- Player.pause(credentials, []),
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

  @impl true
  def search_cover_tracks(%Provider.Spotify{} = provider) do
    search(provider, build_cover_track_search_params())
  end

  @impl true
  def search(%Provider.Spotify{} = provider, params) do
    with {:ok, credentials} <- ensure_credentials(provider),
         response <- Search.query(credentials, params),
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
         response <- Search.query(credentials, params) do
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
         response <- Search.query(credentials, params),
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

  @spec authenticate(Plug.Conn.t() | Credentials.t(), map()) ::
          {:ok, Provider.Spotify.t()} | {:error, term()}
  def authenticate(conn_or_credentials, params) do
    with {:ok, credentials} <- get_credentials(conn_or_credentials),
         {:ok, new_credentials} <- Authentication.authenticate(credentials, params),
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

  defp get_credentials(%Plug.Conn{} = conn), do: {:ok, Credentials.new(conn)}
  defp get_credentials(%Credentials{} = creds), do: {:ok, creds}
  defp get_credentials(_), do: {:error, :invalid_credentials}

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

  defp build_cover_track_search_params do
    query = generate_random_track_query()
    offset = generate_random_offset()

    [
      q: query,
      type: "track",
      limit: @cover_tracks_limit,
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

  defp ensure_credentials(%Credentials{} = credentials), do: {:ok, credentials}

  defp ensure_credentials(%{access_token: access_token} = params) when is_struct(params) and is_binary(access_token) do
    ensure_credentials(Map.from_struct(params))
  end

  defp ensure_credentials(%{access_token: access_token} = params) when is_binary(access_token) do
    credentials = struct(Credentials, params)

    {:ok, credentials}
  end

  defp ensure_credentials(_), do: {:error, :invalid_credentials}

  defp handle_api_response({:error, reason}), do: {:error, reason}
  defp handle_api_response({:ok, %{"error" => %{"message" => reason}}}), do: {:error, reason}
  defp handle_api_response({:ok, %{"error" => reason}}) when is_binary(reason), do: {:error, reason}
  defp handle_api_response({:ok, result}), do: {:ok, result}
  defp handle_api_response(:ok), do: {:ok, :ok}
  defp handle_api_response(result), do: {:ok, result}
end
