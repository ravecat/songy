defmodule Songy.Boundary.Provider.SpotifyTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Provider.Spotify, as: BoundarySpotify
  alias Songy.Core.Provider
  alias Songy.Core.Track
  alias Spotify.Authentication
  alias Spotify.Credentials
  alias Spotify.Player
  alias Spotify.Search

  describe "authenticate/2" do
    test "returns provider data when authentication succeeds with Spotify.Credentials" do
      conn_credentials = %Credentials{access_token: "existing_token"}
      params = %{"code" => "valid_auth_code"}

      credentials = %Credentials{
        access_token: "new_access_token",
        refresh_token: "new_refresh_token"
      }

      Repatch.patch(Authentication, :authenticate, fn _creds, _params ->
        {:ok, credentials}
      end)

      assert {:ok, result} = BoundarySpotify.authenticate(conn_credentials, params)
      assert result.access_token == "new_access_token"
      assert result.refresh_token == "new_refresh_token"
      assert Map.has_key?(result, :expires_at)
    end

    test "returns provider data when authentication succeeds with Plug.Conn" do
      conn = %Plug.Conn{}
      params = %{"code" => "valid_auth_code"}

      credentials = %Credentials{
        access_token: "new_access_token",
        refresh_token: "new_refresh_token"
      }

      Repatch.patch(Credentials, :new, fn _conn -> credentials end)

      Repatch.patch(Authentication, :authenticate, fn _creds, _params ->
        {:ok, credentials}
      end)

      assert {:ok, result} = BoundarySpotify.authenticate(conn, params)
      assert result.access_token == "new_access_token"
      assert result.refresh_token == "new_refresh_token"
      assert Map.has_key?(result, :expires_at)
    end

    test "handles errors when authentication fails" do
      conn_credentials = %Credentials{access_token: "existing_token"}
      params = %{"code" => "valid_code"}

      Repatch.patch(Authentication, :authenticate, fn _creds, _params ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} = BoundarySpotify.authenticate(conn_credentials, params)
    end

    test "returns error when invalid credentials are provided" do
      invalid_input = "not_credentials"
      params = %{"code" => "valid_code"}

      assert {:error, :invalid_credentials} = BoundarySpotify.authenticate(invalid_input, params)
    end
  end

  describe "start_playback/2" do
    test "returns success when Spotify.Player.play succeeds" do
      provider = %Provider.Spotify{access_token: "valid_token", device_id: "test_device"}
      track = %Track{meta: %{uri: "spotify:track:test123"}}

      Repatch.patch(Player, :play, fn _credentials, _params ->
        :ok
      end)

      assert {:ok, :playback_started} = BoundarySpotify.start_playback(provider, track)
    end

    test "returns error when Spotify.Player.play fails" do
      provider = %Provider.Spotify{access_token: "valid_token", device_id: "test_device"}
      track = %Track{meta: %{uri: "spotify:track:test123"}}

      Repatch.patch(Player, :play, fn _credentials, _params ->
        {:error, :api_error}
      end)

      assert {:error, :playback_start_failed} = BoundarySpotify.start_playback(provider, track)
    end

    test "returns error when credentials have no access_token" do
      provider = %Provider.Spotify{device_id: "test_device"}
      track = %Track{meta: %{uri: "spotify:track:test123"}}

      Repatch.patch(Player, :play, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = BoundarySpotify.start_playback(provider, track)
    end

    test "returns error when credentials are empty" do
      provider = %Provider.Spotify{}
      track = %Track{meta: %{uri: "spotify:track:test123"}}

      Repatch.patch(Player, :play, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = BoundarySpotify.start_playback(provider, track)
    end
  end

  describe "pause_playback/2" do
    test "returns success when Spotify.Player.pause succeeds" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Player, :pause, fn _credentials, _params ->
        :ok
      end)

      assert {:ok, :playback_paused} = BoundarySpotify.pause_playback(credentials)
    end

    test "returns error when Spotify.Player.pause fails" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Player, :pause, fn _credentials, _params ->
        {:error, :api_error}
      end)

      assert {:error, :playback_pause_failed} = BoundarySpotify.pause_playback(credentials)
    end

    test "returns error when credentials have no access_token" do
      credentials = %{device_id: "test_device"}

      Repatch.patch(Player, :pause, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = BoundarySpotify.pause_playback(credentials)
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Player, :pause, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = BoundarySpotify.pause_playback(credentials)
    end
  end

  describe "search/2" do
    test "calls Spotify.Search.query with provided params" do
      credentials = %{access_token: "valid_token"}
      params = [q: "test query", type: "track", limit: 10]

      Repatch.patch(Search, :query, fn _credentials, args ->
        assert args == params
        {:ok, %{items: []}}
      end)

      BoundarySpotify.search(credentials, params)
    end

    test "returns error when credentials have no access_token" do
      credentials = %{device_id: "test_device"}

      Repatch.patch(Search, :query, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      params = [q: "test query", type: "track"]
      assert {:error, :invalid_credentials} = BoundarySpotify.search(credentials, params)
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Search, :query, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      params = [q: "test query", type: "track"]
      assert {:error, :invalid_credentials} = BoundarySpotify.search(credentials, params)
    end

    test "calls Spotify.Search.query with explicit empty params" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Search, :query, fn _credentials, args ->
        assert args == []
        {:ok, %{items: []}}
      end)

      BoundarySpotify.search(credentials, [])
    end
  end

  describe "search_random_track/1" do
    test "calls Spotify.Search.query with random track params and converts result" do
      provider = %Provider.Spotify{access_token: "valid_token"}
      expected_track = %Track{id: "test"}

      Repatch.patch(Search, :query, fn _credentials, params ->
        assert params[:q] =~ ~r/^[a-zA-Z] year:\d{4}-\d{4}$/
        assert params[:type] == "track"
        assert params[:limit] == 2
        assert is_integer(params[:offset])
        assert params[:offset] >= 0
        assert params[:offset] <= 999

        {:ok, %{items: [%{id: "test"}]}}
      end)

      Repatch.patch(Songy.Core.Trackable, :to_track, fn %{id: "test"} ->
        expected_track
      end)

      assert {:ok, ^expected_track} = BoundarySpotify.search_random_track(provider)
    end

    test "returns error when provider has no access_token" do
      provider = %Provider.Spotify{device_id: "test_device"}

      assert {:error, :invalid_credentials} = BoundarySpotify.search_random_track(provider)
    end

    test "returns error when provider data is empty" do
      assert {:error, :invalid_credentials} = BoundarySpotify.search_random_track(%Provider.Spotify{})
    end
  end

  describe "search_cover_tracks/1" do
    test "uses provider-defined Spotify search params and converts result" do
      provider = %Provider.Spotify{access_token: "valid_token"}
      expected_track = %Track{id: "test"}

      Repatch.patch(Search, :query, fn _credentials, params ->
        assert params[:q] =~ ~r/^[a-zA-Z] year:\d{4}-\d{4}$/
        assert params[:type] == "track"
        assert params[:limit] == 50
        assert is_integer(params[:offset])
        assert params[:offset] >= 0
        assert params[:offset] <= 999

        {:ok, %{items: [%{id: "test"}]}}
      end)

      Repatch.patch(Songy.Core.Trackable, :to_track, fn %{id: "test"} ->
        expected_track
      end)

      assert {:ok, [^expected_track]} = BoundarySpotify.search_cover_tracks(provider)
    end
  end

  describe "ensure/1" do
    test "refreshes token when access_token expired" do
      fixed_time = ~U[2025-07-15 12:00:00Z]
      expires_at = DateTime.add(fixed_time, -3600, :second)
      expected_expires_at = DateTime.add(fixed_time, 3600, :second)

      credentials = %Provider.Spotify{
        access_token: "expired_token",
        refresh_token: "valid_refresh_token",
        expires_at: expires_at
      }

      new_credentials = %Credentials{access_token: "new_access_token", refresh_token: "valid_refresh_token"}

      Repatch.patch(DateTime, :utc_now, fn -> fixed_time end)

      Repatch.patch(Authentication, :refresh, fn _spotify_creds ->
        {:ok, new_credentials}
      end)

      assert {:ok, :spotify, result} = BoundarySpotify.ensure(credentials)
      assert result.access_token == "new_access_token"
      assert result.refresh_token == "valid_refresh_token"
      assert result.expires_at == expected_expires_at
    end

    test "preserves token when expiring in future" do
      fixed_time = ~U[2025-07-15 12:00:00Z]
      expires_at = DateTime.add(fixed_time, 200, :second)

      credentials = %Provider.Spotify{
        access_token: "valid_token",
        refresh_token: "valid_refresh_token",
        expires_at: expires_at
      }

      Repatch.patch(DateTime, :utc_now, fn -> fixed_time end)

      assert {:ok, :spotify, ^credentials} = BoundarySpotify.ensure(credentials)
    end

    test "preserves token when access_token valid and not expired" do
      expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)

      credentials = %Provider.Spotify{
        access_token: "valid_token",
        refresh_token: "refresh_token",
        expires_at: expires_at
      }

      assert {:ok, :spotify, ^credentials} = BoundarySpotify.ensure(credentials)
    end

    test "returns error when refresh_token present but Spotify API fails" do
      credentials = %Provider.Spotify{access_token: "", refresh_token: "valid_refresh_token"}

      Repatch.patch(Authentication, :refresh, fn _spotify_creds ->
        {:error, :invalid_grant}
      end)

      assert {:error, :invalid_grant} = BoundarySpotify.ensure(credentials)
    end

    test "preserves token when still valid" do
      current_time = DateTime.utc_now()
      expires_at = DateTime.add(current_time, 1800, :second)

      credentials = %Provider.Spotify{
        access_token: "valid_token",
        refresh_token: "valid_refresh_token",
        expires_at: expires_at
      }

      Repatch.patch(DateTime, :utc_now, fn -> current_time end)

      assert {:ok, :spotify, ^credentials} = BoundarySpotify.ensure(credentials)
    end

    test "refreshes token when expired" do
      current_time = ~U[2024-01-01 12:00:00Z]
      expires_at = DateTime.add(current_time, -60, :second)

      credentials = %Provider.Spotify{
        access_token: "expired_token",
        refresh_token: "valid_refresh_token",
        expires_at: expires_at
      }

      new_credentials = %Credentials{
        access_token: "new_access_token",
        refresh_token: "valid_refresh_token"
      }

      Repatch.patch(DateTime, :utc_now, fn -> current_time end)

      Repatch.patch(Authentication, :refresh, fn _spotify_creds ->
        {:ok, new_credentials}
      end)

      assert {:ok, :spotify, result} = BoundarySpotify.ensure(credentials)
      assert result.access_token == "new_access_token"
      assert result.expires_at == DateTime.add(current_time, 3600, :second)
    end
  end
end
