defmodule Songy.Boundary.Provider.Apple do
  @moduledoc """
  Boundary module for Apple Music functionality.

  Provides search functionality using Apple Music API with Developer Token authentication.
  Unlike Spotify, Apple Music uses a shared Developer Token configured at application level.
  """

  require Logger

  use Songy.Boundary.Provider

  alias Songy.Core.Provider
  alias Songy.Core.Track
  alias Songy.Core.Trackable

  @storefront "us"
  @types "songs"
  @limit 25
  @excluded_random_track_genres ["Classical", "Christian", "Children's Music"]
  @random_track_attempts 5
  @cover_request_count 3
  @cover_track_count 45
  @cover_search_attempts 5

  @impl true
  def ensure(_provider), do: {:ok, :apple, Provider.Apple.new()}

  @impl true
  def start_playback(_provider, _track) do
    {:ok, :playback_started}
  end

  @impl true
  def pause_playback(_provider) do
    {:ok, :playback_paused}
  end

  @impl true
  def search_random_track(%Provider.Apple{}) do
    with {:ok, track} <- find_random_track(@random_track_attempts) do
      {:ok, Trackable.to_track(track)}
    end
  end

  @impl true
  def search_cover_tracks(%Provider.Apple{}) do
    collect_cover_tracks([], @cover_search_attempts)
  end

  @impl true
  def search(%Provider.Apple{}, params) do
    with {:ok, %{"songs" => %{"data" => data}}} <- search_catalog(params) do
      tracks = Enum.map(data, &(Track.Apple.to_struct(&1) |> Trackable.to_track()))
      {:ok, tracks}
    else
      {:ok, _} -> {:ok, []}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec access_token() :: String.t()
  defp access_token do
    Application.fetch_env!(:songy, :apple)
    |> Keyword.fetch!(:access_token)
  end

  @spec search_catalog(keyword()) :: {:ok, map()} | {:error, :search_failed}
  defp search_catalog(params) do
    token = access_token()

    with {storefront, search_params} = Keyword.pop(params, :storefront, @storefront),
         result <-
           Req.get("#{base_url()}/catalog/#{storefront}/search",
             headers: [
               {"Authorization", "Bearer #{token}"},
               {"Content-Type", "application/json"}
             ],
             params: search_params
           ),
         {:ok, %{status: 200, body: %{"results" => results}}} <- result do
      Logger.info(
        "Apple Music API request storefront=#{storefront} params=#{inspect(search_params)} successful: #{search_result_count(results)} results"
      )

      Logger.info("Apple Music API request result: #{inspect(result)}")
      {:ok, results}
    else
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

  ## Returns

    * `{:ok, track}` - Apple Music Track.Apple struct
    * `{:error, :search_failed}` - Apple Music API error (propagated from `search/2`)
    * `{:error, :no_tracks_found}` - No tracks found after several random search attempts

  ## Examples

      Songy.Boundary.Provider.Apple.search_random_track()
      # => {:ok, %Track.Apple{id: "1613600188", attributes: %{"name" => "Entropy", ...}}}

  """
  @spec search_random_track() ::
          {:ok, Track.Apple.t()} | {:error, :search_failed | :no_tracks_found}
  def search_random_track do
    find_random_track(@random_track_attempts)
  end

  defp build_random_search_params(overrides \\ []) do
    year = random_year()
    letter = random_letter()
    offset = weighted_cover_offset(year)

    Keyword.merge(
      [
        storefront: @storefront,
        types: @types,
        term: "#{<<letter>>} #{year}",
        limit: @limit,
        offset: offset
      ],
      overrides
    )
  end

  defp random_letter, do: ?a + rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(1)), 26)

  defp random_year do
    first = 1900
    last = Date.utc_today().year
    first + rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(2)), last - first + 1)
  end

  defp weighted_cover_offset(year) do
    pages = cover_offset_pages_for_year(year)
    page = Enum.at(pages, rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(1)), length(pages)))

    page * @limit
  end

  defp cover_offset_pages_for_year(year) do
    cond do
      year < 1950 -> [0, 0, 0, 1]
      year < 1980 -> [0, 0, 1, 1, 2, 2, 3]
      year < 2000 -> [0, 1, 1, 2, 2, 3, 4, 5, 6]
      true -> Enum.to_list(0..11)
    end
  end

  defp find_random_track(0) do
    Logger.warning("No Apple Music tracks found after #{@random_track_attempts} attempts")
    {:error, :no_tracks_found}
  end

  defp find_random_track(attempts_left) do
    params = build_random_search_params()

    case search_catalog(params) do
      {:ok, %{"songs" => %{"data" => [_ | _] = data}}} ->
        filtered_data =
          Enum.reject(data, fn
            %{"attributes" => %{"genreNames" => genre_names}} when is_list(genre_names) ->
              Enum.any?(genre_names, &(&1 in @excluded_random_track_genres))

            _track ->
              false
          end)

        case filtered_data do
          [] ->
            Logger.warning("No Apple Music songs remained after genre filtering for params: #{inspect(params)}")
            find_random_track(attempts_left - 1)

          filtered_data ->
            track =
              filtered_data
              |> Enum.at(rem(:binary.decode_unsigned(:crypto.strong_rand_bytes(1)), length(filtered_data)))
              |> Track.Apple.to_struct()

            Logger.info("Successfully found random track #{inspect(track)} with params: #{inspect(params)}")
            {:ok, track}
        end

      {:ok, %{"songs" => %{"data" => []}}} ->
        Logger.warning("No Apple Music songs found for params: #{inspect(params)}")
        find_random_track(attempts_left - 1)

      {:ok, %{}} ->
        Logger.warning("No Apple Music songs found for params: #{inspect(params)}")
        find_random_track(attempts_left - 1)

      {:ok, _results} ->
        Logger.warning("Unexpected Apple Music search payload for params: #{inspect(params)}")
        find_random_track(attempts_left - 1)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # We repeat cover searches to improve UX by collecting enough unique artwork for the landing grid.
  # If API rate limits become a concern, prefer stopping retries over aggressively pursuing the target.
  defp collect_cover_tracks(unique_tracks, attempts_left) do
    case length(unique_tracks) >= @cover_track_count or attempts_left == 0 do
      true ->
        cover_tracks = Enum.take(unique_tracks, @cover_track_count)

        if length(cover_tracks) < @cover_track_count do
          Logger.warning(
            "Apple Music cover search collected #{length(cover_tracks)}/#{@cover_track_count} unique cover tracks"
          )
        end

        {:ok, cover_tracks}

      false ->
        params_batch =
          Enum.map(1..@cover_request_count, fn _ ->
            build_random_search_params()
          end)

        round_tracks =
          params_batch
          |> Task.async_stream(&search_catalog/1,
            ordered: false,
            max_concurrency: @cover_request_count
          )
          |> extract_cover_tracks()

        unique_tracks =
          (unique_tracks ++ round_tracks)
          |> Enum.filter(&is_binary(&1.cover_url))
          |> Enum.uniq_by(& &1.cover_url)

        collect_cover_tracks(unique_tracks, attempts_left - 1)
    end
  end

  defp extract_cover_tracks(tracks) do
    Enum.reduce(tracks, [], fn
      {:ok, {:ok, %{"songs" => %{"data" => data}}}}, acc ->
        acc ++ Enum.map(data, &(Track.Apple.to_struct(&1) |> Trackable.to_track()))

      {:ok, {:ok, _}}, acc ->
        acc

      {:ok, {:error, reason}}, acc ->
        Logger.warning("Apple Music cover search failed: #{inspect(reason)}")
        acc

      {:exit, reason}, acc ->
        Logger.warning("Apple Music cover search task exited: #{inspect(reason)}")
        acc
    end)
  end

  defp search_result_count(results) when is_map(results) do
    Enum.reduce(results, 0, fn
      {_type, %{"data" => data}}, acc when is_list(data) -> acc + length(data)
      {_type, _group}, acc -> acc
    end)
  end

  defp search_result_count(_results), do: 0

  defp base_url do
    Application.fetch_env!(:songy, :providers)
    |> Keyword.fetch!(:apple)
    |> Keyword.fetch!(:url)
  end
end
