defmodule Songy.Core.ProviderTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Provider
  alias Spotify.Credentials

  describe "Provider" do
    test "creates provider with id only" do
      provider = Provider.new(:spotify)

      assert %Provider{} = provider
      assert provider.id == :spotify
      assert provider.meta == %{}
    end

    test "creates provider with id and meta" do
      meta = %{client_id: "abc123", market: "US"}
      provider = Provider.new(:spotify, meta)

      assert provider.id == :spotify
      assert provider.meta.client_id == "abc123"
      assert provider.meta.market == "US"
    end

    test "creates provider for any provider type" do
      spotify = Provider.new(:spotify)
      apple_music = Provider.new(:apple_music)
      youtube = Provider.new(:youtube)

      assert spotify.id == :spotify
      assert apple_music.id == :apple_music
      assert youtube.id == :youtube
    end

    test "returns basic provider structure for unknown provider types" do
      unknown = Provider.new(:unknown_provider, %{custom: "data"})

      assert %Provider{} = unknown
      assert unknown.id == :unknown_provider
      assert unknown.meta.custom == "data"
      refute Map.has_key?(unknown.meta, :expires_at)
    end

    test "works with different provider types" do
      spotify = Provider.new(:spotify, %{token: "spotify_token"})
      unknown = Provider.new(:unknown, %{token: "unknown_token"})

      assert spotify.id == :spotify
      assert spotify.meta.token == "spotify_token"
      assert unknown.id == :unknown
      assert unknown.meta.token == "unknown_token"
    end

    test "updates provider using specific provider implementation" do
      provider = Provider.new(:spotify, %{old_token: "old"})
      credentials = %{access_token: "new_token", refresh_token: "refresh"}

      updated_provider = Provider.update(provider, credentials)

      assert %Provider{} = updated_provider
      assert updated_provider.id == :spotify
      assert updated_provider.meta.access_token == "new_token"
      assert updated_provider.meta.refresh_token == "refresh"
      assert Map.has_key?(updated_provider.meta, :expires_at)
    end

    test "falls back to basic merge for unknown providers" do
      provider = %Provider{id: :unknown, meta: %{old_data: "old"}}
      patch = %{new_data: "new", old_data: "updated"}

      updated_provider = Provider.update(provider, patch)

      assert %Provider{} = updated_provider
      assert updated_provider.id == :unknown
      assert updated_provider.meta.old_data == "updated"
      assert updated_provider.meta.new_data == "new"
      refute Map.has_key?(updated_provider.meta, :expires_at)
    end

    test "preserves existing metadata when updating" do
      provider = Provider.new(:spotify, %{existing: "value"})
      patch = %{new_field: "new_value"}

      updated_provider = Provider.update(provider, patch)

      assert updated_provider.meta.existing == "value"
      assert updated_provider.meta.new_field == "new_value"
    end
  end

  describe "Provider.Spotify" do
    alias Songy.Core.Provider.Spotify

    test "update/2 with credentials containing access_token" do
      credentials = %{access_token: "abc123", refresh_token: "def456"}
      provider = %Provider{id: :spotify, meta: %{}}

      result = Spotify.update(provider, credentials)

      assert %Provider{} = result
      assert result.meta.access_token == "abc123"
      assert result.meta.refresh_token == "def456"
      assert %DateTime{} = result.meta.expires_at
      assert DateTime.diff(result.meta.expires_at, DateTime.utc_now(), :second) in 3590..3610
    end

    test "update/2 preserves existing fields" do
      credentials = %{
        access_token: "token",
        refresh_token: "refresh",
        scope: "user-read-private",
        token_type: "Bearer"
      }

      provider = %Provider{id: :spotify, meta: %{}}

      result = Spotify.update(provider, credentials)

      assert result.meta.access_token == "token"
      assert result.meta.refresh_token == "refresh"
      assert result.meta.scope == "user-read-private"
      assert result.meta.token_type == "Bearer"
      assert Map.has_key?(result.meta, :expires_at)
    end

    test "update/2 handles struct input by converting to map" do
      credentials = Credentials.new(%Plug.Conn{})

      provider = %Provider{id: :spotify, meta: %{}}

      result = Spotify.update(provider, credentials)

      assert %Provider{} = result
      assert Map.has_key?(result.meta, :access_token)
      assert Map.has_key?(result.meta, :refresh_token)
      assert Map.has_key?(result.meta, :expires_at)
    end

    test "update/2 handles map input directly" do
      credentials = %{
        access_token: "map_token",
        refresh_token: "map_refresh"
      }

      provider = %Provider{id: :spotify, meta: %{}}

      result = Spotify.update(provider, credentials)

      assert %Provider{} = result
      assert result.meta.access_token == "map_token"
      assert result.meta.refresh_token == "map_refresh"
      assert Map.has_key?(result.meta, :expires_at)
    end

    test "update/2 with regular patch data" do
      patch = %{custom_field: "value", market: "US"}
      provider = %Provider{id: :spotify, meta: %{existing: "data"}}

      result = Spotify.update(provider, patch)

      assert %Provider{} = result
      assert result.meta.existing == "data"
      assert result.meta.custom_field == "value"
      assert result.meta.market == "US"
      refute Map.has_key?(result.meta, :expires_at)
    end
  end
end
