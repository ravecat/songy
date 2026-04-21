defmodule Songy.Boundary.Provider.AppleTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Provider.Apple

  @random_track_attempts 5
  @valid_token "test_developer_token"

  setup do
    Application.put_env(:songy, :apple, access_token: @valid_token)
    :ok
  end

  describe "search/2" do
    test "returns tracks when search is successful" do
      expected_response = %{
        status: 200,
        body: %{
          "results" => %{
            "songs" => %{
              "data" => [
                %{
                  "id" => "123",
                  "type" => "songs",
                  "attributes" => %{
                    "name" => "Test Song",
                    "artistName" => "Test Artist",
                    "releaseDate" => "2020-01-01"
                  }
                }
              ]
            }
          }
        }
      }

      Repatch.patch(Req, :get, fn _url, _opts -> {:ok, expected_response} end)

      assert {:ok, [%Songy.Core.Track{title: "Test Song", artist: "Test Artist", year: 2020}]} =
               Apple.search(%Songy.Core.Provider.Apple{}, term: "test")
    end

    test "returns error when API request fails" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:error, %RuntimeError{message: "Network error"}}
      end)

      assert {:error, :search_failed} = Apple.search(%Songy.Core.Provider.Apple{}, term: "test")
    end

    test "returns empty tracks when Apple Music returns no result groups" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      assert {:ok, []} = Apple.search(%Songy.Core.Provider.Apple{}, term: "test")
    end

    test "does not include storefront in query params when not specified" do
      Repatch.patch(Req, :get, fn _url, opts ->
        params = Keyword.get(opts, :params)
        refute Keyword.has_key?(params, :storefront)
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      Apple.search(%Songy.Core.Provider.Apple{}, term: "test")
    end

    test "removes custom storefront from query params before request" do
      Repatch.patch(Req, :get, fn _url, opts ->
        params = Keyword.get(opts, :params)
        refute Keyword.has_key?(params, :storefront)
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      Apple.search(%Songy.Core.Provider.Apple{}, term: "test", storefront: "gb")
    end

    test "passes query params directly to Req without normalization" do
      Repatch.patch(Req, :get, fn _url, opts ->
        params = Keyword.get(opts, :params)
        assert Keyword.get(params, :term) == "beatles"
        assert Keyword.get(params, :entity) == "song"
        assert Keyword.get(params, :limit) == 50
        refute Keyword.has_key?(params, :types)
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      Apple.search(%Songy.Core.Provider.Apple{}, term: "beatles", entity: "song", limit: 50)
    end

    test "handles API error responses" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:ok, %{status: 401, body: %{"errors" => [%{"status" => "401"}]}}}
      end)

      assert {:error, :search_failed} = Apple.search(%Songy.Core.Provider.Apple{}, term: "test")
    end

    test "includes Authorization header with Bearer token" do
      Repatch.patch(Req, :get, fn _url, opts ->
        headers = Keyword.get(opts, :headers)
        assert {"Authorization", "Bearer test_developer_token"} in headers

        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      Apple.search(%Songy.Core.Provider.Apple{}, term: "test")
    end

    test "includes Content-Type header" do
      Repatch.patch(Req, :get, fn _url, opts ->
        headers = Keyword.get(opts, :headers)
        assert {"Content-Type", "application/json"} in headers
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      Apple.search(%Songy.Core.Provider.Apple{}, term: "test")
    end
  end

  describe "search/2 with missing config" do
    test "raises when Apple config is missing" do
      Application.delete_env(:songy, :apple)

      assert_raise ArgumentError, fn ->
        Apple.search(%Songy.Core.Provider.Apple{}, term: "test")
      end
    end
  end

  describe "ensure/1" do
    test "returns Apple provider without requiring configured credentials" do
      Application.delete_env(:songy, :apple)

      assert {:ok, :apple, %Songy.Core.Provider.Apple{}} = Apple.ensure(%Songy.Core.Provider.Apple{})
    end
  end

  describe "search_cover_tracks/1" do
    test "runs three parallel cover searches, uses bounded offsets, and dedupes by cover_url" do
      {:ok, calls} = Agent.start_link(fn -> {0, []} end)

      shared_artwork = %{"url" => "https://example.test/shared/{w}x{h}bb.jpg"}
      unique_artwork = %{"url" => "https://example.test/unique/{w}x{h}bb.jpg"}

      Repatch.patch(Req, :get, [mode: :shared], fn url, opts ->
        call_index =
          Agent.get_and_update(calls, fn {index, recorded} ->
            params = Keyword.fetch!(opts, :params)
            next = index + 1
            {next, {next, [params | recorded]}}
          end)

        assert url =~ ~r"/catalog/us/search$"

        body =
          case call_index do
            1 ->
              songs_response([
                song_payload("1", "Shared A", "Artist A", "2020-01-01", shared_artwork)
              ])

            2 ->
              songs_response([
                song_payload("2", "Shared B", "Artist B", "2021-01-01", shared_artwork)
              ])

            _ ->
              songs_response([
                song_payload("3", "Unique", "Artist C", "2022-01-01", unique_artwork)
              ])
          end

        {:ok, %{status: 200, body: body}}
      end)

      assert {:ok, tracks} = Apple.search_cover_tracks(%Songy.Core.Provider.Apple{})
      assert length(tracks) == 2

      recorded =
        Agent.get(calls, fn {_count, recorded} ->
          Enum.reverse(recorded)
        end)

      assert length(recorded) == 3
      assert Enum.all?(recorded, &(Keyword.fetch!(&1, :types) == "songs"))
      assert Enum.all?(recorded, &(Keyword.fetch!(&1, :limit) == 25))
      assert Enum.all?(recorded, &(Keyword.fetch!(&1, :term) =~ ~r/^[a-z] \d{4}$/))
      assert Enum.all?(recorded, &(rem(Keyword.fetch!(&1, :offset), 25) == 0))
      assert recorded |> Enum.map(&Keyword.fetch!(&1, :offset)) |> Enum.uniq() |> length() == 3
    end

    test "returns partial unique cover results when one parallel request fails" do
      {:ok, calls} = Agent.start_link(fn -> 0 end)

      Repatch.patch(Req, :get, [mode: :shared], fn _url, _opts ->
        call_index =
          Agent.get_and_update(calls, fn count ->
            next = count + 1
            {next, next}
          end)

        case call_index do
          1 ->
            {:error, %RuntimeError{message: "Network error"}}

          2 ->
            {:ok,
             %{
               status: 200,
               body:
                 songs_response([
                   song_payload("2", "A", "B", "2020-01-01", %{
                     "url" => "https://example.test/a/{w}x{h}bb.jpg"
                   })
                 ])
             }}

          _ ->
            {:ok,
             %{
               status: 200,
               body:
                 songs_response([
                   song_payload("3", "C", "D", "2020-01-01", %{
                     "url" => "https://example.test/c/{w}x{h}bb.jpg"
                   })
                 ])
             }}
        end
      end)

      assert {:ok, tracks} = Apple.search_cover_tracks(%Songy.Core.Provider.Apple{})
      assert length(tracks) == 2
    end

    test "returns an empty list when all parallel requests fail" do
      Repatch.patch(Req, :get, [mode: :shared], fn _url, _opts ->
        {:error, %RuntimeError{message: "Network error"}}
      end)

      assert {:ok, []} = Apple.search_cover_tracks(%Songy.Core.Provider.Apple{})
    end
  end

  describe "search_random_track/0" do
    test "returns random track when search is successful" do
      tracks = [
        %{"id" => "123", "attributes" => %{"name" => "Track 1"}},
        %{"id" => "456", "attributes" => %{"name" => "Track 2"}},
        %{"id" => "789", "attributes" => %{"name" => "Track 3"}}
      ]

      expected_response = %{
        status: 200,
        body: %{
          "results" => %{
            "songs" => %{
              "data" => tracks
            }
          }
        }
      }

      Repatch.patch(Req, :get, fn _url, _opts -> {:ok, expected_response} end)

      assert {:ok, %Songy.Core.Track.Apple{id: id} = track} = Apple.search_random_track()
      assert id in ["123", "456", "789"]
      assert is_map(track.attributes)
    end

    test "retries when Apple Music returns no result groups" do
      Process.put(:apple_req_calls, 0)

      Repatch.patch(Req, :get, fn _url, _opts ->
        Process.put(:apple_req_calls, Process.get(:apple_req_calls, 0) + 1)
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      assert {:error, :no_tracks_found} = Apple.search_random_track()
      assert Process.get(:apple_req_calls) == @random_track_attempts
    end

    test "returns error when response has unexpected structure" do
      expected_response = %{
        status: 200,
        body: %{
          "results" => %{
            "albums" => %{
              "data" => [%{"id" => "123"}]
            }
          }
        }
      }

      Repatch.patch(Req, :get, fn _url, _opts -> {:ok, expected_response} end)

      assert {:error, :no_tracks_found} = Apple.search_random_track()
    end

    test "retries empty search results until tracks are found" do
      tracks = [
        %{"id" => "123", "attributes" => %{"name" => "Track 1"}},
        %{"id" => "456", "attributes" => %{"name" => "Track 2"}}
      ]

      Process.put(:apple_req_calls, 0)

      Repatch.patch(Req, :get, fn _url, _opts ->
        calls = Process.get(:apple_req_calls, 0) + 1
        Process.put(:apple_req_calls, calls)

        case calls do
          1 ->
            {:ok, %{status: 200, body: %{"results" => %{}}}}

          _ ->
            {:ok,
             %{
               status: 200,
               body: %{
                 "results" => %{
                   "songs" => %{
                     "data" => tracks
                   }
                 }
               }
             }}
        end
      end)

      assert {:ok, %Songy.Core.Track.Apple{id: id}} = Apple.search_random_track()
      assert id in ["123", "456"]
      assert Process.get(:apple_req_calls) == 2
    end

    test "returns error when API request fails" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:error, %RuntimeError{message: "Network error"}}
      end)

      assert {:error, :search_failed} = Apple.search_random_track()
    end

    test "uses correct search parameters" do
      Repatch.patch(Req, :get, fn url, opts ->
        params = Keyword.get(opts, :params)

        assert url =~ ~r"/catalog/us/search$"
        assert Keyword.get(params, :types) == "songs"
        assert Keyword.get(params, :limit) == 25
        assert is_binary(Keyword.get(params, :term))
        assert Keyword.get(params, :term) =~ ~r/^[a-z] \d{4}$/
        refute Keyword.has_key?(params, :offset)

        {:ok,
         %{
           status: 200,
           body: %{
             "results" => %{
               "songs" => %{
                 "data" => [%{"id" => "123", "attributes" => %{"name" => "Test"}}]
               }
             }
           }
         }}
      end)

      Apple.search_random_track()
    end

    test "handles API error responses" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:ok, %{status: 500, body: %{"errors" => [%{"status" => "500"}]}}}
      end)

      assert {:error, :search_failed} = Apple.search_random_track()
    end

    test "returns single track from multiple results" do
      tracks =
        Enum.map(1..25, fn i ->
          %{"id" => "#{i}", "attributes" => %{"name" => "Track #{i}"}}
        end)

      expected_response = %{
        status: 200,
        body: %{
          "results" => %{
            "songs" => %{
              "data" => tracks
            }
          }
        }
      }

      Repatch.patch(Req, :get, fn _url, _opts -> {:ok, expected_response} end)

      assert {:ok, %Songy.Core.Track.Apple{id: id} = track} = Apple.search_random_track()
      assert is_binary(id)
      assert is_map(track.attributes)
      assert track.attributes["name"] =~ ~r/Track \d+/
    end
  end

  describe "search_random_track/0 with missing config" do
    test "raises when Apple config is missing" do
      Application.delete_env(:songy, :apple)

      assert_raise ArgumentError, fn ->
        Apple.search_random_track()
      end
    end
  end

  defp songs_response(data) do
    %{"results" => %{"songs" => %{"data" => data}}}
  end

  defp song_payload(id, name, artist, release_date, artwork) do
    %{
      "id" => id,
      "type" => "songs",
      "attributes" => %{
        "name" => name,
        "artistName" => artist,
        "releaseDate" => release_date,
        "artwork" => artwork
      }
    }
  end
end
