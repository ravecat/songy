defmodule Songy.Boundary.SpotifyTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Provider
  alias Songy.Boundary

  describe "transfer_playback/2" do
    test "returns error when device_id is missing from payload" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      assert {:error, :no_device_id} = Boundary.Spotify.transfer_playback(provider, %{})
    end

    test "returns error when payload has no device_id" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      assert {:error, :no_device_id} = Boundary.Spotify.transfer_playback(provider, %{"other_key" => "value"})
    end

    test "returns error when provider has no access_token" do
      provider = Provider.new(:spotify, %{device_id: "test_device"})

      assert {:error, :no_credentials} = Boundary.Spotify.transfer_playback(provider, %{"device_id" => "test_device"})
    end

    test "returns error when provider has nil access_token" do
      provider = %Provider{
        id: :spotify,
        meta: %Provider.Spotify{access_token: nil, device_id: "test_device"}
      }

      assert {:error, :no_credentials} = Boundary.Spotify.transfer_playback(provider, %{"device_id" => "test_device"})
    end

    test "returns error when provider is not Spotify" do
      provider = Provider.new(:youtube, %{access_token: "token"})

      assert {:error, :invalid_provider} = Boundary.Spotify.transfer_playback(provider, %{"device_id" => "test_device"})
    end

    test "returns error when provider is nil" do
      assert {:error, :invalid_provider} = Boundary.Spotify.transfer_playback(nil, %{"device_id" => "test_device"})
    end

    test "returns success when transfer_playback succeeds" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids ->
        :ok
      end)

      assert {:ok, :transferred} = Boundary.Spotify.transfer_playback(provider, %{"device_id" => "test_device"})
    end

    test "returns error when Spotify.Player.transfer_playback fails" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      Repatch.patch(Spotify.Player, :transfer_playback, fn _credentials, _device_ids ->
        {:error, :device_not_found}
      end)

      assert {:error, :transfer_failed} = Boundary.Spotify.transfer_playback(provider, %{"device_id" => "test_device"})
    end
  end

  describe "start_playback/2" do
    test "returns success when Spotify.Player.play succeeds" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      Repatch.patch(Spotify.Player, :play, fn _credentials, _params ->
        :ok
      end)

      assert {:ok, :playback_started} = Boundary.Spotify.start_playback(provider)
    end

    test "returns error when Spotify.Player.play fails" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      Repatch.patch(Spotify.Player, :play, fn _credentials, _params ->
        {:error, :api_error}
      end)

      assert {:error, :playback_start_failed} = Boundary.Spotify.start_playback(provider)
    end

    test "returns error when provider has no access_token" do
      provider = Provider.new(:spotify, %{device_id: "test_device"})

      assert {:error, :no_credentials} = Boundary.Spotify.start_playback(provider)
    end

    test "returns error when provider is not Spotify" do
      provider = Provider.new(:youtube, %{access_token: "token"})

      assert {:error, :invalid_provider} = Boundary.Spotify.start_playback(provider)
    end
  end

  describe "pause_playback/2" do
    test "returns success when Spotify.Player.pause succeeds" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      Repatch.patch(Spotify.Player, :pause, fn _credentials, _params ->
        :ok
      end)

      assert {:ok, :playback_paused} = Boundary.Spotify.pause_playback(provider)
    end

    test "returns error when Spotify.Player.pause fails" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      Repatch.patch(Spotify.Player, :pause, fn _credentials, _params ->
        {:error, :api_error}
      end)

      assert {:error, :playback_pause_failed} = Boundary.Spotify.pause_playback(provider)
    end

    test "returns error when provider has no access_token" do
      provider = Provider.new(:spotify, %{device_id: "test_device"})

      assert {:error, :no_credentials} = Boundary.Spotify.pause_playback(provider)
    end

    test "returns error when provider is not Spotify" do
      provider = Provider.new(:youtube, %{access_token: "token"})

      assert {:error, :invalid_provider} = Boundary.Spotify.pause_playback(provider)
    end
  end

  describe "search/2" do
    test "calls Spotify.Search.query with provided params" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})
      params = [q: "test query", type: "track", limit: 10]

      Repatch.patch(Spotify.Search, :query, fn _credentials, args ->
        assert args == params
        {:ok, %{items: []}}
      end)

      Boundary.Spotify.search(provider, params)
    end

    test "returns error when provider has no access_token" do
      provider = Provider.new(:spotify, %{device_id: "test_device"})

      params = [q: "test query", type: "track"]
      assert {:error, :no_credentials} = Boundary.Spotify.search(provider, params)
    end

    test "returns error when provider is not Spotify" do
      provider = Provider.new(:youtube, %{access_token: "token"})

      params = [q: "test query", type: "track"]
      assert {:error, :invalid_provider} = Boundary.Spotify.search(provider, params)
    end

    test "calls Spotify.Search.query with empty params by default" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      Repatch.patch(Spotify.Search, :query, fn _credentials, args ->
        assert args == []
        {:ok, %{items: []}}
      end)

      Boundary.Spotify.search(provider)
    end
  end

  describe "search_random_track/1" do
    test "calls Spotify.Search.query with random track params" do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      Repatch.patch(Spotify.Search, :query, fn _credentials, params ->
        assert params[:q] =~ ~r/^\*[a-zA-Z]\* year:\d{4}-\d{4}$/
        assert params[:type] == "track"
        assert params[:limit] == 1
        assert is_integer(params[:offset])
        assert params[:offset] >= 0
        assert params[:offset] <= 999

        {:ok, %{items: [%{id: "test"}]}}
      end)

      Boundary.Spotify.search_random_track(provider)
    end

    test "returns error when provider has no access_token" do
      provider = Provider.new(:spotify, %{device_id: "test_device"})

      assert {:error, :no_credentials} = Boundary.Spotify.search_random_track(provider)
    end

    test "returns error when provider is not Spotify" do
      provider = Provider.new(:youtube, %{access_token: "token"})

      assert {:error, :invalid_provider} = Boundary.Spotify.search_random_track(provider)
    end
  end
end
