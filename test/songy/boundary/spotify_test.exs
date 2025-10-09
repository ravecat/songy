defmodule Songy.Boundary.SpotifyTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary
  alias Songy.Core.Provider

  describe "authenticate/2" do
    test "returns provider data when authentication succeeds" do
      conn_credentials = %Spotify.Credentials{access_token: "existing_token"}
      params = %{"code" => "valid_auth_code"}

      credentials = %Spotify.Credentials{
        access_token: "new_access_token",
        refresh_token: "new_refresh_token"
      }

      Repatch.patch(Spotify.Authentication, :authenticate, fn _conn, _params ->
        {:ok, credentials}
      end)

      assert {:ok, result} = Boundary.Spotify.authenticate(conn_credentials, params)
      assert result.access_token == "new_access_token"
      assert result.refresh_token == "new_refresh_token"
      assert Map.has_key?(result, :expires_at)
    end

    test "handles errors when authentication fails" do
      conn_credentials = %Spotify.Credentials{access_token: "existing_token"}
      params = %{"code" => "valid_code"}

      Repatch.patch(Spotify.Authentication, :authenticate, fn _conn, _params ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} = Boundary.Spotify.authenticate(conn_credentials, params)
    end
  end

  describe "transfer_playback/2" do
    test "works with Spotify.Credentials struct" do
      credentials = %Spotify.Credentials{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids, _params ->
        :ok
      end)

      assert {:ok, :playback_transferred} =
               Boundary.Spotify.transfer_playback(credentials, %{"device_id" => "test_device"})
    end

    test "works with map containing access_token and refresh_token" do
      credentials = %{access_token: "valid_token", refresh_token: "refresh_token"}

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids, _params ->
        :ok
      end)

      assert {:ok, :playback_transferred} =
               Boundary.Spotify.transfer_playback(credentials, %{"device_id" => "test_device"})
    end

    test "returns error when device_id is missing from payload" do
      credentials = %{access_token: "valid_token"}

      assert {:error, :no_device_id} = Boundary.Spotify.transfer_playback(credentials, %{})
    end

    test "returns error when credentials have no access_token" do
      credentials = %{}

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} =
               Boundary.Spotify.transfer_playback(credentials, %{"device_id" => "test_device"})
    end

    test "returns error when credentials have nil access_token" do
      credentials = %{access_token: nil}

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} =
               Boundary.Spotify.transfer_playback(credentials, %{"device_id" => "test_device"})
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} =
               Boundary.Spotify.transfer_playback(credentials, %{"device_id" => "test_device"})
    end

    test "returns error when credentials are nil" do
      assert {:error, :invalid_credentials} = Boundary.Spotify.transfer_playback(nil, %{"device_id" => "test_device"})
    end

    test "returns success when transfer_playback succeeds" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids, _params ->
        :ok
      end)

      assert {:ok, :playback_transferred} =
               Boundary.Spotify.transfer_playback(credentials, %{"device_id" => "test_device"})
    end

    test "returns error when Spotify.Player.transfer_playback fails" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids, _params ->
        {:error, :device_not_found}
      end)

      assert {:error, :playback_transfer_failed} =
               Boundary.Spotify.transfer_playback(credentials, %{"device_id" => "test_device"})
    end
  end

  describe "start_playback/2" do
    test "returns success when Spotify.Player.play succeeds" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :play, fn _credentials, _params ->
        :ok
      end)

      assert {:ok, :playback_started} = Boundary.Spotify.start_playback(credentials)
    end

    test "returns error when Spotify.Player.play fails" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :play, fn _credentials, _params ->
        {:error, :api_error}
      end)

      assert {:error, :playback_start_failed} = Boundary.Spotify.start_playback(credentials)
    end

    test "returns error when credentials have no access_token" do
      credentials = %{device_id: "test_device"}

      Repatch.patch(Spotify.Player, :play, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = Boundary.Spotify.start_playback(credentials)
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Spotify.Player, :play, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = Boundary.Spotify.start_playback(credentials)
    end
  end

  describe "pause_playback/2" do
    test "returns success when Spotify.Player.pause succeeds" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :pause, fn _credentials, _params ->
        :ok
      end)

      assert {:ok, :playback_paused} = Boundary.Spotify.pause_playback(credentials)
    end

    test "returns error when Spotify.Player.pause fails" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :pause, fn _credentials, _params ->
        {:error, :api_error}
      end)

      assert {:error, :playback_pause_failed} = Boundary.Spotify.pause_playback(credentials)
    end

    test "returns error when credentials have no access_token" do
      credentials = %{device_id: "test_device"}

      Repatch.patch(Spotify.Player, :pause, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = Boundary.Spotify.pause_playback(credentials)
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Spotify.Player, :pause, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = Boundary.Spotify.pause_playback(credentials)
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

      Boundary.Spotify.search(credentials, params)
    end

    test "returns error when credentials have no access_token" do
      credentials = %{device_id: "test_device"}

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      params = [q: "test query", type: "track"]
      assert {:error, :invalid_credentials} = Boundary.Spotify.search(credentials, params)
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      params = [q: "test query", type: "track"]
      assert {:error, :invalid_credentials} = Boundary.Spotify.search(credentials, params)
    end

    test "calls Spotify.Search.query with empty params by default" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Search, :query, fn _credentials, args ->
        assert args == []
        {:ok, %{items: []}}
      end)

      Boundary.Spotify.search(credentials)
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

      Boundary.Spotify.search_random_track(credentials)
    end

    test "returns error when credentials have no access_token" do
      credentials = %{device_id: "test_device"}

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = Boundary.Spotify.search_random_track(credentials)
    end

    test "returns error when credentials are empty" do
      credentials = %{}

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:error, :invalid_request}
      end)

      assert {:error, :invalid_credentials} = Boundary.Spotify.search_random_track(credentials)
    end

    test "works with Spotify.Credentials struct" do
      credentials = %Spotify.Credentials{access_token: "valid_token"}

      Repatch.patch(Spotify.Search, :query, fn _credentials, _params ->
        {:ok, %{items: [%{id: "test"}]}}
      end)

      assert {:ok, %{id: "test"}} = Boundary.Spotify.search_random_track(credentials)
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

      assert {:ok, result} = Boundary.Spotify.ensure_provider_data(credentials)
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

      assert {:ok, ^credentials} = Boundary.Spotify.ensure_provider_data(credentials)
    end

    test "preserves token when access_token valid and not expired" do
      expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)

      credentials = %Provider.Spotify{
        access_token: "valid_token",
        refresh_token: "refresh_token",
        expires_at: expires_at
      }

      assert {:ok, ^credentials} = Boundary.Spotify.ensure_provider_data(credentials)
    end

    test "returns error when refresh_token present but Spotify API fails" do
      credentials = %Provider.Spotify{access_token: "", refresh_token: "valid_refresh_token"}

      Repatch.patch(Spotify.Authentication, :refresh, fn _spotify_creds ->
        {:error, :invalid_grant}
      end)

      assert {:error, :invalid_grant} = Boundary.Spotify.ensure_provider_data(credentials)
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

      assert {:ok, ^credentials} = Boundary.Spotify.ensure_provider_data(credentials)
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

      assert {:ok, result} = Boundary.Spotify.ensure_provider_data(credentials)
      assert result.access_token == "new_access_token"
      assert result.expires_at == DateTime.add(current_time, 3600, :second)
    end
  end
end
