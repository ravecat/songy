defmodule Songy.Boundary.Provider.SpotifyTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Provider.Spotify, as: BoundarySpotify
  alias Songy.Core.Provider

  describe "authenticate/2" do
    test "returns provider data when authentication succeeds with Spotify.Credentials" do
      conn_credentials = %Spotify.Credentials{access_token: "existing_token"}
      params = %{"code" => "valid_auth_code"}

      credentials = %Spotify.Credentials{
        access_token: "new_access_token",
        refresh_token: "new_refresh_token"
      }

      Repatch.patch(Spotify.Authentication, :authenticate, fn _creds, _params ->
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

      credentials = %Spotify.Credentials{
        access_token: "new_access_token",
        refresh_token: "new_refresh_token"
      }

      Repatch.patch(Spotify.Credentials, :new, fn _conn -> credentials end)

      Repatch.patch(Spotify.Authentication, :authenticate, fn _creds, _params ->
        {:ok, credentials}
      end)

      assert {:ok, result} = BoundarySpotify.authenticate(conn, params)
      assert result.access_token == "new_access_token"
      assert result.refresh_token == "new_refresh_token"
      assert Map.has_key?(result, :expires_at)
    end

    test "handles errors when authentication fails" do
      conn_credentials = %Spotify.Credentials{access_token: "existing_token"}
      params = %{"code" => "valid_code"}

      Repatch.patch(Spotify.Authentication, :authenticate, fn _creds, _params ->
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
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :play, fn _credentials, _params ->
        :ok
      end)

      assert {:ok, :playback_started} = BoundarySpotify.start_playback(credentials)
    end

    test "returns error when Spotify.Player.play fails" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :play, fn _credentials, _params ->
        {:error, :api_error}
      end)

      assert {:error, :playback_start_failed} = BoundarySpotify.start_playback(credentials)
    end

    test "returns error when credentials have no access_token" do
      credentials = %{device_id: "test_device"}

      Repatch.patch(Spotify.Player, :play, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = BoundarySpotify.start_playback(credentials)
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Spotify.Player, :play, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = BoundarySpotify.start_playback(credentials)
    end
  end

  describe "pause_playback/2" do
    test "returns success when Spotify.Player.pause succeeds" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :pause, fn _credentials, _params ->
        :ok
      end)

      assert {:ok, :playback_paused} = BoundarySpotify.pause_playback(credentials)
    end

    test "returns error when Spotify.Player.pause fails" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :pause, fn _credentials, _params ->
        {:error, :api_error}
      end)

      assert {:error, :playback_pause_failed} = BoundarySpotify.pause_playback(credentials)
    end

    test "returns error when credentials have no access_token" do
      credentials = %{device_id: "test_device"}

      Repatch.patch(Spotify.Player, :pause, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = BoundarySpotify.pause_playback(credentials)
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Spotify.Player, :pause, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = BoundarySpotify.pause_playback(credentials)
    end
  end

  describe "search/2" do
    test "calls Spotify.Search.query with provided params" do
      credentials = %{access_token: "valid_token"}
      params = [q: "test query", type: "track", limit: 10]

      Repatch.patch(Spotify.Search, :query, fn _credentials, args ->
        assert args == params
        {:ok, %{items: []}}
      end)

      BoundarySpotify.search(credentials, params)
    end

    test "returns error when credentials have no access_token" do
      credentials = %{device_id: "test_device"}

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      params = [q: "test query", type: "track"]
      assert {:error, :invalid_credentials} = BoundarySpotify.search(credentials, params)
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      params = [q: "test query", type: "track"]
      assert {:error, :invalid_credentials} = BoundarySpotify.search(credentials, params)
    end

    test "calls Spotify.Search.query with empty params by default" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Search, :query, fn _credentials, args ->
        assert args == []
        {:ok, %{items: []}}
      end)

      BoundarySpotify.search(credentials)
    end
  end

  describe "search_random_track/1" do
    test "calls Spotify.Search.query with random track params" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Search, :query, fn _credentials, params ->
        assert params[:q] =~ ~r/^[a-zA-Z] year:\d{4}-\d{4}$/
        assert params[:type] == "track"
        assert params[:limit] == 2
        assert is_integer(params[:offset])
        assert params[:offset] >= 0
        assert params[:offset] <= 999

        {:ok, %{items: [%{id: "test"}]}}
      end)

      BoundarySpotify.search_random_track(credentials)
    end

    test "returns error when credentials have no access_token" do
      credentials = %{device_id: "test_device"}

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = BoundarySpotify.search_random_track(credentials)
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = BoundarySpotify.search_random_track(credentials)
    end

    test "works with Spotify.Credentials struct" do
      credentials = %Spotify.Credentials{access_token: "valid_token"}

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:ok, %{items: [%{id: "test"}]}}
      end)

      assert {:ok, %{id: "test"}} = BoundarySpotify.search_random_track(credentials)
    end
  end

  describe "ensure_provider_data/1" do
    test "refreshes token when access_token expired" do
      fixed_time = ~U[2025-07-15 12:00:00Z]
      expires_at = DateTime.add(fixed_time, -3600, :second)
      expected_expires_at = DateTime.add(fixed_time, 3600, :second)

      credentials = %Provider.Spotify{
        access_token: "expired_token",
        refresh_token: "valid_refresh_token",
        expires_at: expires_at
      }

      new_credentials = %Spotify.Credentials{access_token: "new_access_token", refresh_token: "valid_refresh_token"}

      Repatch.patch(DateTime, :utc_now, fn -> fixed_time end)

      Repatch.patch(Spotify.Authentication, :refresh, fn _spotify_creds ->
        {:ok, new_credentials}
      end)

      assert {:ok, result} = BoundarySpotify.ensure_provider_data(credentials)
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

      assert {:ok, ^credentials} = BoundarySpotify.ensure_provider_data(credentials)
    end

    test "preserves token when access_token valid and not expired" do
      expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)

      credentials = %Provider.Spotify{
        access_token: "valid_token",
        refresh_token: "refresh_token",
        expires_at: expires_at
      }

      assert {:ok, ^credentials} = BoundarySpotify.ensure_provider_data(credentials)
    end

    test "returns error when refresh_token present but Spotify API fails" do
      credentials = %Provider.Spotify{access_token: "", refresh_token: "valid_refresh_token"}

      Repatch.patch(Spotify.Authentication, :refresh, fn _spotify_creds ->
        {:error, :invalid_grant}
      end)

      assert {:error, :invalid_grant} = BoundarySpotify.ensure_provider_data(credentials)
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

      assert {:ok, ^credentials} = BoundarySpotify.ensure_provider_data(credentials)
    end

    test "refreshes token when expired" do
      current_time = ~U[2024-01-01 12:00:00Z]
      expires_at = DateTime.add(current_time, -60, :second)

      credentials = %Provider.Spotify{
        access_token: "expired_token",
        refresh_token: "valid_refresh_token",
        expires_at: expires_at
      }

      new_credentials = %Spotify.Credentials{
        access_token: "new_access_token",
        refresh_token: "valid_refresh_token"
      }

      Repatch.patch(DateTime, :utc_now, fn -> current_time end)

      Repatch.patch(Spotify.Authentication, :refresh, fn _spotify_creds ->
        {:ok, new_credentials}
      end)

      assert {:ok, result} = BoundarySpotify.ensure_provider_data(credentials)
      assert result.access_token == "new_access_token"
      assert result.expires_at == DateTime.add(current_time, 3600, :second)
    end
  end
end
