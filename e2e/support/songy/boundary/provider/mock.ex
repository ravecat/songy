defimpl Songy.Boundary.Provider, for: Songy.Core.Provider.Mock do
  alias Songy.Core.Provider
  alias Songy.Core.Track

  def ensure(_provider) do
    {:ok, :itunes, Provider.Mock.new()}
  end

  def start_playback(_provider, _track) do
    {:ok, :playback_started}
  end

  def pause_playback(_provider) do
    {:ok, :playback_paused}
  end

  def search_random_track(_provider) do
    {:ok,
     %Track{
       id: "mock-random-track",
       title: "Mock Random Track",
       artist: "Songy Mock",
       year: 2000,
       cover_url: cover_data_uri(0),
       meta: %{preview_url: nil}
     }}
  end

  def search(_provider, params) do
    limit =
      case Keyword.get(params, :limit, 50) do
        value when is_integer(value) and value > 0 -> min(value, 100)
        _ -> 50
      end

    tracks =
      Enum.map(1..limit, fn index ->
        %Track{
          id: "mock-cover-track-#{index}",
          title: "Mock Title #{index}",
          artist: "Mock Artist",
          year: 1970 + rem(index, 40),
          cover_url: cover_data_uri(index),
          meta: %{preview_url: nil}
        }
      end)

    {:ok, tracks}
  end

  defp cover_data_uri(seed) when is_integer(seed) do
    hue = rem(seed * 53 + 17, 360)

    svg = """
    <svg xmlns='http://www.w3.org/2000/svg' width='300' height='300' viewBox='0 0 300 300'>
      <rect width='300' height='300' fill='hsl(#{hue} 55% 45%)' />
    </svg>
    """

    "data:image/svg+xml;base64," <> Base.encode64(svg)
  end
end
