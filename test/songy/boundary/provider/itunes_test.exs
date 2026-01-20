defmodule Songy.Boundary.Provider.ITunesTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Provider.ITunes

  describe "search/1" do
    test "returns results when search is successful" do
      expected_response = %{
        status: 200,
        body: %{
          "resultCount" => 1,
          "results" => [
            %{
              "trackId" => 123,
              "trackName" => "Test Song",
              "artistName" => "Test Artist",
              "collectionName" => "Test Album",
              "releaseDate" => "2020-01-01T00:00:00Z",
              "previewUrl" => "https://audio-ssl.itunes.apple.com/preview.m4a",
              "artworkUrl100" => "https://is1-ssl.mzstatic.com/image/thumb/Music/100x100bb.jpg",
              "kind" => "song"
            }
          ]
        }
      }

      Repatch.patch(Req, :get, fn _url, _opts -> {:ok, expected_response} end)

      assert {:ok, [track]} = ITunes.search(term: "test")
      assert track["trackId"] == 123
      assert track["trackName"] == "Test Song"
      assert track["artistName"] == "Test Artist"
      assert track["collectionName"] == "Test Album"
    end

    test "returns error when API request fails" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:error, %RuntimeError{message: "Network error"}}
      end)

      assert {:error, :search_failed} = ITunes.search(term: "test")
    end

    test "passes query params directly to Req" do
      Repatch.patch(Req, :get, fn _url, opts ->
        params = Keyword.get(opts, :params)
        assert Keyword.get(params, :term) == "beatles"
        assert Keyword.get(params, :entity) == "album"
        assert Keyword.get(params, :limit) == 10
        assert Keyword.get(params, :country) == "gb"
        {:ok, %{status: 200, body: %{"resultCount" => 0, "results" => []}}}
      end)

      ITunes.search(term: "beatles", entity: "album", limit: 10, country: "gb")
    end

    test "handles API error responses" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:ok, %{status: 500, body: %{"errorMessage" => "Failure"}}}
      end)

      assert {:error, :search_failed} = ITunes.search(term: "test")
    end

    test "does not include Authorization header" do
      Repatch.patch(Req, :get, fn _url, opts ->
        headers = Keyword.get(opts, :headers, [])
        refute Enum.any?(headers, fn {key, _} -> key == "Authorization" end)
        {:ok, %{status: 200, body: %{"resultCount" => 0, "results" => []}}}
      end)

      ITunes.search(term: "test")
    end
  end

  describe "search_random_track/0" do
    test "returns random track when search is successful" do
      tracks = [
        %{
          "trackId" => 123,
          "trackName" => "Track 1",
          "artistName" => "Artist 1",
          "collectionName" => "Album 1",
          "kind" => "song",
          "previewUrl" => "https://example.com/preview.m4a",
          "artworkUrl100" => "https://example.com/artwork.jpg"
        },
        %{
          "trackId" => 456,
          "trackName" => "Track 2",
          "artistName" => "Artist 2",
          "collectionName" => "Album 2",
          "kind" => "song",
          "previewUrl" => "https://example.com/preview.m4a",
          "artworkUrl100" => "https://example.com/artwork.jpg"
        },
        %{
          "trackId" => 789,
          "trackName" => "Track 3",
          "artistName" => "Artist 3",
          "collectionName" => "Album 3",
          "kind" => "song",
          "previewUrl" => "https://example.com/preview.m4a",
          "artworkUrl100" => "https://example.com/artwork.jpg"
        }
      ]

      expected_response = %{status: 200, body: %{"resultCount" => 3, "results" => tracks}}

      Repatch.patch(Req, :get, fn _url, _opts -> {:ok, expected_response} end)

      assert {:ok, %Songy.Core.Track.ITunes{} = track} = ITunes.search_random_track()
      assert track.trackName in ["Track 1", "Track 2", "Track 3"]
      assert track.artistName in ["Artist 1", "Artist 2", "Artist 3"]
      assert track.previewUrl == "https://example.com/preview.m4a"
      assert track.artworkUrl100 == "https://example.com/artwork.jpg"
    end

    test "returns error when no tracks found" do
      expected_response = %{status: 200, body: %{"resultCount" => 0, "results" => []}}

      Repatch.patch(Req, :get, fn _url, _opts -> {:ok, expected_response} end)

      assert {:error, :no_tracks_found} = ITunes.search_random_track()
    end

    test "returns error when only non-song results" do
      expected_response = %{
        status: 200,
        body: %{"resultCount" => 1, "results" => [%{"kind" => "album", "collectionId" => 123}]}
      }

      Repatch.patch(Req, :get, fn _url, _opts -> {:ok, expected_response} end)

      assert {:error, :no_tracks_found} = ITunes.search_random_track()
    end

    test "returns error when API request fails" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:error, %RuntimeError{message: "Network error"}}
      end)

      assert {:error, :search_failed} = ITunes.search_random_track()
    end

    test "uses correct search parameters" do
      Repatch.patch(Req, :get, fn _url, opts ->
        params = Keyword.get(opts, :params)

        assert Keyword.get(params, :entity) == "song"
        assert Keyword.get(params, :media) == "music"
        assert Keyword.get(params, :limit) == 25
        assert is_binary(Keyword.get(params, :term))
        assert Keyword.get(params, :term) =~ ~r/^[a-z]\*$/
        assert is_integer(Keyword.get(params, :offset))

        {:ok, %{status: 200, body: %{"resultCount" => 1, "results" => [%{"trackId" => 123, "kind" => "song"}]}}}
      end)

      ITunes.search_random_track()
    end

    test "handles API error responses" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:ok, %{status: 500, body: %{"errorMessage" => "Failure"}}}
      end)

      assert {:error, :search_failed} = ITunes.search_random_track()
    end

    test "returns single track from multiple results" do
      tracks =
        Enum.map(1..25, fn i ->
          %{
            "trackId" => i,
            "trackName" => "Track #{i}",
            "artistName" => "Artist",
            "collectionName" => "Album",
            "kind" => "song",
            "previewUrl" => "https://example.com/preview.m4a",
            "artworkUrl100" => "https://example.com/artwork.jpg"
          }
        end)

      expected_response = %{status: 200, body: %{"resultCount" => 25, "results" => tracks}}

      Repatch.patch(Req, :get, fn _url, _opts -> {:ok, expected_response} end)

      assert {:ok, %Songy.Core.Track.ITunes{} = track} = ITunes.search_random_track()
      assert track.trackName =~ ~r/Track \d+/
      assert track.artistName == "Artist"
      assert track.previewUrl == "https://example.com/preview.m4a"
      assert track.artworkUrl100 == "https://example.com/artwork.jpg"
    end
  end
end
