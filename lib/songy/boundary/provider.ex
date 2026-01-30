defprotocol Songy.Boundary.Provider do
  @fallback_to_any true

  @moduledoc """
  Protocol for music provider operations.

  Defines a unified interface for credential management and playback control
  across different music providers (Spotify, Apple Music, iTunes, etc.).

  All functions return standardized response tuples with generic error atoms
  for consistent error handling across the application.
  """

  @doc """
  Ensures that provider credentials and data are fresh and valid.
  """
  @spec ensure(t()) :: {:ok, term()} | {:error, atom()}
  def ensure(provider)

  @spec start_playback(t(), Songy.Core.Track.t()) :: {:ok, term()} | {:error, atom()}
  def start_playback(provider, track)

  @spec pause_playback(t()) :: {:ok, term()} | {:error, atom()}
  def pause_playback(provider)

  @spec search_random_track(t()) :: {:ok, Songy.Core.Track.t()} | {:error, atom()}
  def search_random_track(provider)

  @spec search(t(), keyword()) :: {:ok, list(Songy.Core.Track.t())} | {:error, atom()}
  def search(provider, params)
end

defimpl Songy.Boundary.Provider, for: Any do
  def ensure(_provider), do: {:error, :not_supported}
  def start_playback(_provider, _track), do: {:error, :not_supported}
  def pause_playback(_provider), do: {:error, :not_supported}
  def search_random_track(_provider), do: {:error, :not_supported}
  def search(_provider, _params), do: {:error, :not_supported}
end

defimpl Songy.Boundary.Provider, for: Songy.Core.Provider.Spotify do
  alias Songy.Boundary.Provider.Spotify
  alias Songy.Core.Provider
  alias Songy.Core.Track
  alias Songy.Core.Trackable

  def ensure(provider) do
    case Spotify.ensure_provider_data(provider) do
      {:ok, ^provider} ->
        {:ok, provider}

      {:ok, credentials} ->
        {:ok, Provider.Spotify.update(provider, Map.from_struct(credentials))}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def start_playback(%{device_id: device_id} = provider, %Track{meta: %{uri: uri}}) do
    Spotify.start_playback(provider, uris: [uri], device_id: device_id)
  end

  def start_playback(_provider, %Track{}) do
    {:error, :missing_track_uri}
  end

  def pause_playback(provider) do
    Spotify.pause_playback(provider)
  end

  def search_random_track(provider) do
    case Spotify.search_random_track(provider) do
      {:ok, track} ->
        {:ok, Trackable.to_track(track)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def search(provider, params) do
    case Spotify.search(provider, params) do
      {:ok, %{items: items}} ->
        {:ok, Enum.map(items, &Trackable.to_track/1)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

defimpl Songy.Boundary.Provider, for: Songy.Core.Provider.Apple do
  alias Songy.Boundary.Provider.Apple
  alias Songy.Core.Provider
  alias Songy.Core.Track
  alias Songy.Core.Trackable

  def ensure(_provider) do
    case Apple.access_token() do
      token when is_binary(token) ->
        {:ok, Provider.Apple.new()}

      _ ->
        {:error, :invalid_credentials}
    end
  end

  def start_playback(_provider, _track) do
    {:ok, :playback_started}
  end

  def pause_playback(_provider) do
    {:ok, :playback_paused}
  end

  def search_random_track(_provider) do
    case Apple.search_random_track() do
      {:ok, track} ->
        {:ok, Trackable.to_track(track)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def search(_provider, params) do
    with {:ok, token} <- Apple.access_token(),
         {:ok, %{"songs" => %{"data" => data}}} <- Apple.search(token, params) do
      tracks = Enum.map(data, &(Track.Apple.to_struct(&1) |> Trackable.to_track()))
      {:ok, tracks}
    else
      {:ok, _} -> {:ok, []}
      {:error, reason} -> {:error, reason}
    end
  end
end

defimpl Songy.Boundary.Provider, for: Songy.Core.Provider.ITunes do
  alias Songy.Boundary.Provider.ITunes
  alias Songy.Core.Provider
  alias Songy.Core.Track
  alias Songy.Core.Trackable

  def ensure(_provider) do
    {:ok, Provider.ITunes.new()}
  end

  def start_playback(_provider, _track) do
    {:ok, :playback_started}
  end

  def pause_playback(_provider) do
    {:ok, :playback_paused}
  end

  def search_random_track(_provider) do
    case ITunes.search_random_track() do
      {:ok, track} ->
        {:ok, Trackable.to_track(track)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def search(_provider, params) do
    case ITunes.search(params) do
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

  defp song?(%{"kind" => "song"}), do: true
  defp song?(_), do: false
end
