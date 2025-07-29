defmodule Songy.Boundary.SpotifyTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary

  describe "transfer_playback/2" do
    test "works with Spotify.Credentials struct" do
      credentials = %Spotify.Credentials{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids ->
        :ok
      end)

      assert {:ok, :playback_transferred} = Boundary.Spotify.transfer_playback(credentials, %{"device_id" => "test_device"})
    end

    test "works with map containing access_token and refresh_token" do
      credentials = %{access_token: "valid_token", refresh_token: "refresh_token"}

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids ->
        :ok
      end)

      assert {:ok, :playback_transferred} = Boundary.Spotify.transfer_playback(credentials, %{"device_id" => "test_device"})
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

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids ->
        :ok
      end)

      assert {:ok, :playback_transferred} = Boundary.Spotify.transfer_playback(credentials, %{"device_id" => "test_device"})
    end

    test "returns error when Spotify.Player.transfer_playback fails" do
      credentials = %{access_token: "valid_token"}

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids ->
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
end
