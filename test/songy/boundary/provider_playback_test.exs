defmodule Songy.Boundary.ProviderPlaybackTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary
  alias Songy.Boundary.Provider
  alias Songy.Core.Track
  alias Songy.Provider.Session

  describe "Spotify provider implementation" do
    setup do
      provider =
        Session.normalize!(%Songy.Core.Provider.Spotify{
          access_token: "valid_token",
          refresh_token: "refresh_token",
          device_id: "test_device",
          expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
        })

      track = %Track{
        id: "track123",
        title: "Test Song",
        artist: "Test Artist",
        year: 2023,
        meta: %{uri: "spotify:track:test123"}
      }

      %{provider: provider, track: track}
    end

    test "start_playback/2 delegates to Spotify.start_playback/2", %{
      provider: provider,
      track: track
    } do
      Repatch.patch(Spotify.Player, :play, fn _credentials, opts ->
        assert opts[:uris] == ["spotify:track:test123"]
        assert opts[:device_id] == "test_device"
        :ok
      end)

      assert {:ok, :playback_started} = Provider.start_playback(provider, track)
      assert Repatch.called?(Spotify.Player, :play, 2)
    end

    test "start_playback/2 returns error when track has no URI", %{provider: provider} do
      track_without_uri = %Track{
        id: "track123",
        title: "Test Song",
        artist: "Test Artist",
        year: 2023,
        meta: %{}
      }

      assert {:error, :missing_track_uri} = Provider.start_playback(provider, track_without_uri)
    end

    test "pause_playback/1 delegates to Spotify.pause_playback/2", %{provider: provider} do
      Repatch.patch(Spotify.Player, :pause, fn _credentials, _opts ->
        :ok
      end)

      assert {:ok, :playback_paused} = Provider.pause_playback(provider)
      assert Repatch.called?(Spotify.Player, :pause, 2)
    end

    test "search_random_track/1 delegates to Spotify.search_random_track/1", %{provider: provider} do
      spotify_track = %{id: "test_track", name: "Test Song"}

      expected_track = %Track{
        id: "generated_id",
        title: "Test Song",
        artist: "Test Artist",
        year: 2023,
        meta: %{}
      }

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:ok, %{items: [spotify_track]}}
      end)

      Repatch.patch(Songy.Core.Trackable, :to_track, fn _spotify_track ->
        expected_track
      end)

      assert {:ok, ^expected_track} = Provider.search_random_track(provider)
      assert Repatch.called?(Spotify.Search, :query, 2)
      assert Repatch.called?(Songy.Core.Trackable, :to_track, 1)
    end

    test "start_playback/2 handles errors from Spotify.start_playback/2", %{
      provider: provider,
      track: track
    } do
      Repatch.patch(Spotify.Player, :play, fn _credentials, _opts ->
        {:error, :invalid_credentials}
      end)

      assert {:error, :invalid_credentials} = Provider.start_playback(provider, track)
    end

    test "pause_playback/1 handles errors from Spotify.pause_playback/2", %{provider: provider} do
      Repatch.patch(Spotify.Player, :pause, fn _credentials, _opts ->
        {:error, :api_error}
      end)

      assert {:error, :playback_pause_failed} = Provider.pause_playback(provider)
    end

    test "search_random_track/1 handles errors from Spotify.search_random_track/1", %{
      provider: provider
    } do
      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:ok, %{items: []}}
      end)

      assert {:error, :no_tracks_found} = Provider.search_random_track(provider)
      assert Repatch.called?(Spotify.Search, :query, 2)
      refute Repatch.called?(Songy.Core.Trackable, :to_track, 1)
    end
  end

  describe "Apple Music provider implementation" do
    setup do
      provider = Session.normalize!(%Songy.Core.Provider.Apple{})

      track = %Track{
        id: "1440783454",
        title: "Firestarter",
        artist: "The Prodigy",
        year: 1996,
        meta: %{}
      }

      %{provider: provider, track: track}
    end

    test "start_playback/2 returns immediate success", %{provider: provider, track: track} do
      assert {:ok, :playback_started} = Provider.start_playback(provider, track)
    end

    test "pause_playback/1 returns immediate success", %{provider: provider} do
      assert {:ok, :playback_paused} = Provider.pause_playback(provider)
    end

    test "search_random_track/1 delegates to Apple.search_random_track/0", %{provider: provider} do
      apple_track = %Songy.Core.Track.Apple{
        id: "1440783454",
        type: "songs",
        href: "/v1/catalog/us/songs/1440783454",
        attributes: %{
          "name" => "Firestarter",
          "artistName" => "The Prodigy",
          "albumName" => "The Fat of the Land",
          "releaseDate" => "1996-06-30"
        }
      }

      expected_track = %Track{
        id: "generated_id",
        title: "Firestarter",
        artist: "The Prodigy",
        year: 1996,
        meta: %{}
      }

      Repatch.patch(Boundary.Provider.Apple, :search_random_track, fn ->
        {:ok, apple_track}
      end)

      Repatch.patch(Songy.Core.Trackable, :to_track, fn _apple_track ->
        expected_track
      end)

      assert {:ok, ^expected_track} = Provider.search_random_track(provider)
      assert Repatch.called?(Boundary.Provider.Apple, :search_random_track, 0)
      assert Repatch.called?(Songy.Core.Trackable, :to_track, 1)
    end

    test "search_random_track/1 handles errors from Apple.search_random_track/0", %{provider: provider} do
      Repatch.patch(Boundary.Provider.Apple, :search_random_track, fn ->
        {:error, :no_tracks_found}
      end)

      assert {:error, :no_tracks_found} = Provider.search_random_track(provider)
      assert Repatch.called?(Boundary.Provider.Apple, :search_random_track, 0)
      refute Repatch.called?(Songy.Core.Trackable, :to_track, 1)
    end
  end

  describe "iTunes provider implementation" do
    setup do
      provider = Session.normalize!(%Songy.Core.Provider.ITunes{})

      track = %Track{
        id: "1440783454",
        title: "Firestarter",
        artist: "The Prodigy",
        year: 1996,
        meta: %{}
      }

      %{provider: provider, track: track}
    end

    test "start_playback/2 returns immediate success", %{provider: provider, track: track} do
      assert {:ok, :playback_started} = Provider.start_playback(provider, track)
    end

    test "pause_playback/1 returns immediate success", %{provider: provider} do
      assert {:ok, :playback_paused} = Provider.pause_playback(provider)
    end

    test "search_random_track/1 delegates to ITunes.search_random_track/0", %{provider: provider} do
      itunes_track = %Songy.Core.Track.Apple{
        id: "1440783454",
        type: "songs",
        href: "https://itunes.apple.com/track/1440783454",
        attributes: %{
          "name" => "Firestarter",
          "artistName" => "The Prodigy",
          "albumName" => "The Fat of the Land",
          "releaseDate" => "1996-06-30"
        }
      }

      expected_track = %Track{
        id: "generated_id",
        title: "Firestarter",
        artist: "The Prodigy",
        year: 1996,
        meta: %{}
      }

      Repatch.patch(Boundary.Provider.ITunes, :search_random_track, fn ->
        {:ok, itunes_track}
      end)

      Repatch.patch(Songy.Core.Trackable, :to_track, fn _itunes_track ->
        expected_track
      end)

      assert {:ok, ^expected_track} = Provider.search_random_track(provider)
      assert Repatch.called?(Boundary.Provider.ITunes, :search_random_track, 0)
      assert Repatch.called?(Songy.Core.Trackable, :to_track, 1)
    end

    test "search_random_track/1 handles errors from ITunes.search_random_track/0", %{provider: provider} do
      Repatch.patch(Boundary.Provider.ITunes, :search_random_track, fn ->
        {:error, :no_tracks_found}
      end)

      assert {:error, :no_tracks_found} = Provider.search_random_track(provider)
      assert Repatch.called?(Boundary.Provider.ITunes, :search_random_track, 0)
      refute Repatch.called?(Songy.Core.Trackable, :to_track, 1)
    end
  end

  describe "unsupported provider implementation" do
    setup do
      unsupported_provider = %{type: :unsupported, name: "Unknown Provider"}

      track = %Track{
        id: "track123",
        title: "Test Song",
        artist: "Test Artist",
        year: 2023,
        meta: %{}
      }

      %{provider: unsupported_provider, track: track}
    end

    test "start_playback/2 returns not_supported error", %{provider: provider, track: track} do
      assert {:error, :not_supported} = Provider.start_playback(provider, track)
    end

    test "pause_playback/1 returns not_supported error", %{provider: provider} do
      assert {:error, :not_supported} = Provider.pause_playback(provider)
    end

    test "search_random_track/1 returns not_supported error", %{provider: provider} do
      assert {:error, :not_supported} = Provider.search_random_track(provider)
    end
  end
end
