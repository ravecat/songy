defmodule Songy.Core.TrackableTest do
  use ExUnit.Case, async: true

  alias Songy.Core.{Track, Trackable}

  describe "Trackable protocol for Spotify.Track" do
    setup do
      track = %Spotify.Track{
        id: "732hl1bSexhqKxC3B0T3IU",
        name: "Via del campo",
        artists: [
          %{
            "external_urls" => %{
              "spotify" => "https://open.spotify.com/artist/19HiWVd2g0XyJstBsbW2Qm"
            },
            "href" => "https://api.spotify.com/v1/artists/19HiWVd2g0XyJstBsbW2Qm",
            "id" => "19HiWVd2g0XyJstBsbW2Qm",
            "name" => "Fabrizio De André",
            "type" => "artist",
            "uri" => "spotify:artist:19HiWVd2g0XyJstBsbW2Qm"
          }
        ],
        album: %{
          "album_type" => "album",
          "artists" => [
            %{
              "external_urls" => %{
                "spotify" => "https://open.spotify.com/artist/19HiWVd2g0XyJstBsbW2Qm"
              },
              "href" => "https://api.spotify.com/v1/artists/19HiWVd2g0XyJstBsbW2Qm",
              "id" => "19HiWVd2g0XyJstBsbW2Qm",
              "name" => "Fabrizio De André",
              "type" => "artist",
              "uri" => "spotify:artist:19HiWVd2g0XyJstBsbW2Qm"
            }
          ],
          "external_urls" => %{
            "spotify" => "https://open.spotify.com/album/7GmZv2K4fIf5uuqz4qIOth"
          },
          "href" => "https://api.spotify.com/v1/albums/7GmZv2K4fIf5uuqz4qIOth",
          "id" => "7GmZv2K4fIf5uuqz4qIOth",
          "images" => [
            %{
              "height" => 640,
              "url" => "https://i.scdn.co/image/ab67616d0000b2738eeb336aff3e753c3359df51",
              "width" => 640
            },
            %{
              "height" => 300,
              "url" => "https://i.scdn.co/image/ab67616d00001e028eeb336aff3e753c3359df51",
              "width" => 300
            },
            %{
              "height" => 64,
              "url" => "https://i.scdn.co/image/ab67616d000048518eeb336aff3e753c3359df51",
              "width" => 64
            }
          ],
          "is_playable" => true,
          "name" => "Volume 1",
          "release_date" => "1967",
          "release_date_precision" => "year",
          "total_tracks" => 10,
          "type" => "album",
          "uri" => "spotify:album:7GmZv2K4fIf5uuqz4qIOth"
        },
        available_markets: [
          "AR",
          "AU",
          "AT",
          "BE",
          "BO",
          "BR",
          "BG",
          "CA",
          "CL",
          "CO",
          "CR",
          "CY",
          "CZ",
          "DK",
          "DO",
          "DE",
          "EC",
          "EE",
          "SV",
          "FI",
          "FR",
          "GR",
          "GT",
          "HN",
          "HK",
          "HU",
          "IS",
          "IE",
          "IT",
          "LV",
          "LT",
          "LU",
          "MY",
          "MT",
          "MX",
          "NL",
          "NZ",
          "NI",
          "NO",
          "PA",
          "PY",
          "PE",
          "PH",
          "PL",
          "PT"
        ],
        disc_number: 1,
        duration_ms: 149_613,
        explicit: false,
        external_ids: %{"isrc" => "ITB007070536"},
        href: "https://api.spotify.com/v1/tracks/732hl1bSexhqKxC3B0T3IU",
        is_playable: true,
        linked_from: nil,
        popularity: 56,
        preview_url: nil,
        track_number: 6,
        type: "track",
        uri: "spotify:track:732hl1bSexhqKxC3B0T3IU"
      }

      {:ok, track: track}
    end

    test "successfully transforms complete Spotify track", %{track: track} do
      result = Trackable.to_track(track)

      assert %Track{} = result
      assert result.title == "Via del campo"
      assert result.artist == "Fabrizio De André"
      assert result.year == 1967
      assert result.cover_url == "https://i.scdn.co/image/ab67616d0000b2738eeb336aff3e753c3359df51"
      assert result.meta == %{uri: "spotify:track:732hl1bSexhqKxC3B0T3IU"}
    end

    test "extracts cover URL from album images", %{track: track} do
      result = Trackable.to_track(track)

      assert %Track{} = result
      assert result.cover_url == "https://i.scdn.co/image/ab67616d0000b2738eeb336aff3e753c3359df51"
    end

    test "handles empty album images array", %{track: track} do
      modified_track = %{track | album: %{track.album | "images" => []}}

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.cover_url == nil
    end

    test "handles missing images field", %{track: track} do
      {_, album_without_images} = Map.pop(track.album, "images")
      modified_track = %{track | album: album_without_images}

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.cover_url == nil
    end

    test "handles multiple artists by joining them with comma", %{track: track} do
      modified_track = %{
        track
        | name: "Collaboration Song",
          artists: [
            %{"name" => "First Artist"},
            %{"name" => "Second Artist"},
            %{"name" => "Third Artist"}
          ]
      }

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.artist == "First Artist, Second Artist, Third Artist"
    end

    test "handles different date formats", %{track: track} do
      test_cases = [
        {"1995-06-01", 1995},
        {"1995-06", 1995},
        {"1995", 1995},
        {"2023-12-25", 2023}
      ]

      for {date_string, expected_year} <- test_cases do
        modified_track = %{track | album: %{track.album | "release_date" => date_string}}

        result = Trackable.to_track(modified_track)
        assert result.year == expected_year
      end
    end

    test "returns nil when release_date is missing", %{track: track} do
      {_, album_without_date} = Map.pop(track.album, "release_date")
      modified_track = %{track | album: album_without_date}

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.year == nil
    end

    test "returns nil when artists array is empty", %{track: track} do
      modified_track = %{track | artists: []}

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.artist == nil
    end

    test "returns nil when artist has no name", %{track: track} do
      modified_track = %{track | artists: [%{"id" => "artist123"}]}

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.artist == nil
    end

    test "returns nil when track name is missing", %{track: track} do
      modified_track = %{track | name: nil}

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.title == nil
    end

    test "returns nil when track name is empty string", %{track: track} do
      modified_track = %{track | name: ""}

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.title == nil
    end

    test "handles invalid date format gracefully", %{track: track} do
      modified_track = %{track | album: %{track.album | "release_date" => "invalid-date"}}

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.year == nil
    end

    test "handles nil album gracefully", %{track: track} do
      modified_track = %{track | album: nil}

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.year == nil
    end

    test "handles artists with empty names", %{track: track} do
      modified_track = %{
        track
        | artists: [
            %{"name" => "Valid Artist"},
            %{"name" => ""},
            %{"name" => "   "},
            %{"name" => "Another Valid"}
          ]
      }

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.artist == "Valid Artist, Another Valid"
    end

    test "handles artists with nil names", %{track: track} do
      modified_track = %{
        track
        | artists: [
            %{"name" => "Valid Artist"},
            %{"name" => nil},
            %{"name" => "Another Valid"}
          ]
      }

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.artist == "Valid Artist, Another Valid"
    end

    test "handles artists without name key", %{track: track} do
      modified_track = %{
        track
        | artists: [
            %{"name" => "Valid Artist"},
            %{"other_field" => "some value"},
            %{"name" => "Another Valid"}
          ]
      }

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.artist == "Valid Artist, Another Valid"
    end

    test "handles all invalid artists", %{track: track} do
      modified_track = %{
        track
        | artists: [
            %{"name" => ""},
            %{"name" => nil},
            %{"other_field" => "value"}
          ]
      }

      result = Trackable.to_track(modified_track)

      assert %Track{} = result
      assert result.artist == nil
    end

    test "handles missing URI field", %{track: track} do
      track_without_uri = %{track | uri: nil}

      result = Trackable.to_track(track_without_uri)

      assert %Track{} = result
      assert result.meta == %{}
    end

    test "handles empty URI field", %{track: track} do
      track_with_empty_uri = %{track | uri: ""}

      result = Trackable.to_track(track_with_empty_uri)

      assert %Track{} = result
      assert result.meta == %{}
    end
  end
end
