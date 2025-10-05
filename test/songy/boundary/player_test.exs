defmodule Songy.Boundary.PlayerTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary
  alias Songy.Boundary.Player

  describe "Spotify provider implementation" do
    setup do
      provider = %Songy.Core.Provider.Spotify{
        access_token: "valid_token",
        refresh_token: "refresh_token",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      %{provider: provider}
    end

    test "start_playback/2 delegates to Spotify.start_playback/2", %{provider: provider} do
      opts = [uris: ["spotify:track:test"], device_id: "test_device"]

      Repatch.patch(Boundary.Spotify, :start_playback, fn _provider, _opts ->
        {:ok, :playback_started}
      end)

      assert {:ok, :playback_started} = Player.start_playback(provider, opts)
      assert Repatch.called?(Boundary.Spotify, :start_playback, 2)
    end

    test "pause_playback/2 delegates to Spotify.pause_playback/2", %{provider: provider} do
      opts = [device_id: "test_device"]

      Repatch.patch(Boundary.Spotify, :pause_playback, fn _provider, _opts ->
        {:ok, :playback_paused}
      end)

      assert {:ok, :playback_paused} = Player.pause_playback(provider, opts)
      assert Repatch.called?(Boundary.Spotify, :pause_playback, 2)
    end

    test "search_random_track/1 delegates to Spotify.search_random_track/1", %{provider: provider} do
      spotify_track = %{id: "test_track", name: "Test Song"}

      expected_track = %Songy.Core.Track{
        id: "generated_id",
        title: "Test Song",
        artist: "Test Artist",
        year: 2023,
        meta: %{}
      }

      Repatch.patch(Boundary.Spotify, :search_random_track, fn _provider ->
        {:ok, spotify_track}
      end)

      Repatch.patch(Songy.Core.Trackable, :to_track, fn _spotify_track ->
        expected_track
      end)

      assert {:ok, ^expected_track} = Player.search_random_track(provider)
      assert Repatch.called?(Boundary.Spotify, :search_random_track, 1)
      assert Repatch.called?(Songy.Core.Trackable, :to_track, 1)
    end

    test "start_playback/2 handles errors from Spotify.start_playback/2", %{provider: provider} do
      Repatch.patch(Boundary.Spotify, :start_playback, fn _provider, _opts ->
        {:error, :invalid_credentials}
      end)

      assert {:error, :invalid_credentials} = Player.start_playback(provider, [])
    end

    test "pause_playback/2 handles errors from Spotify.pause_playback/2", %{provider: provider} do
      Repatch.patch(Boundary.Spotify, :pause_playback, fn _provider, _opts ->
        {:error, :playback_pause_failed}
      end)

      assert {:error, :playback_pause_failed} = Player.pause_playback(provider, [])
    end

    test "search_random_track/1 handles errors from Spotify.search_random_track/1", %{
      provider: provider
    } do
      Repatch.patch(Boundary.Spotify, :search_random_track, fn _provider ->
        {:error, :no_tracks_found}
      end)

      assert {:error, :no_tracks_found} = Player.search_random_track(provider)
      assert Repatch.called?(Boundary.Spotify, :search_random_track, 1)
      refute Repatch.called?(Songy.Core.Trackable, :to_track, 1)
    end
  end

  describe "unsupported provider implementation" do
    setup do
      unsupported_provider = %{type: :unsupported, name: "Unknown Provider"}
      %{provider: unsupported_provider}
    end

    test "start_playback/2 returns not_supported error", %{provider: provider} do
      assert {:error, :not_supported} = Player.start_playback(provider, [])
    end

    test "pause_playback/2 returns not_supported error", %{provider: provider} do
      assert {:error, :not_supported} = Player.pause_playback(provider, [])
    end

    test "search_random_track/1 returns not_supported error", %{provider: provider} do
      assert {:error, :not_supported} = Player.search_random_track(provider)
    end

    test "pause_playback/1 with default opts returns not_supported error", %{provider: provider} do
      assert {:error, :not_supported} = Player.pause_playback(provider)
    end
  end
end
