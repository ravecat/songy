defmodule Songy.Core.Trackable.AppleTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Track
  alias Songy.Core.Trackable

  describe "Trackable protocol for Track.Apple" do
    test "successfully transforms complete Apple Music track with preview URL" do
      track = %Songy.Core.Track.Apple{
        id: "1440783454",
        type: "songs",
        href: "/v1/catalog/us/songs/1440783454",
        attributes: %{
          "name" => "Firestarter",
          "artistName" => "The Prodigy",
          "albumName" => "The Fat of the Land",
          "releaseDate" => "1996-06-30",
          "artwork" => %{
            "url" => "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/a1/b2/c3/{w}x{h}bb.jpg",
            "width" => 1400,
            "height" => 1400
          },
          "previews" => [
            %{"url" => "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/f1/e2/d3/f1e2d3c4-1234-5678-9abc-def012345678/mzaf_1234567890123456789.plus.aac.p.m4a"}
          ],
          "durationInMillis" => 276_000
        }
      }

      result = Trackable.to_track(track)

      assert %Track{} = result
      assert result.title == "Firestarter"
      assert result.artist == "The Prodigy"
      assert result.year == 1996
      assert result.cover_url == "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/a1/b2/c3/640x640bb.jpg"
      assert result.meta.preview_url == "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/f1/e2/d3/f1e2d3c4-1234-5678-9abc-def012345678/mzaf_1234567890123456789.plus.aac.p.m4a"
    end

    test "handles missing previews array" do
      track = %Songy.Core.Track.Apple{
        id: "202",
        type: "songs",
        href: "/v1/catalog/us/songs/202",
        attributes: %{
          "name" => "No Preview Song",
          "artistName" => "Artist",
          "releaseDate" => "2023-01-01"
        }
      }

      result = Trackable.to_track(track)

      assert result.meta == %{}
    end

    test "handles empty previews array" do
      track = %Songy.Core.Track.Apple{
        id: "303",
        type: "songs",
        href: "/v1/catalog/us/songs/303",
        attributes: %{
          "name" => "Empty Previews",
          "artistName" => "Artist",
          "releaseDate" => "2023-01-01",
          "previews" => []
        }
      }

      result = Trackable.to_track(track)

      assert result.meta == %{}
    end
  end
end
