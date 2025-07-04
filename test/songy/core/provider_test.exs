defmodule Songy.Core.ProviderTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Provider

  # Test struct for simulating Spotify.Credentials
  defmodule TestCredentials do
    defstruct [:access_token, :refresh_token, :scope, :token_type]
  end

  describe "Provider.new/2" do
    test "creates provider with id only" do
      provider = Provider.new(:spotify)

      assert %Provider{} = provider
      assert provider.id == :spotify
      assert Map.has_key?(provider.meta, :expires_at)
    end

    test "creates provider with id and meta" do
      meta = %{client_id: "abc123", market: "US"}
      provider = Provider.new(:spotify, meta)

      assert provider.id == :spotify
      assert provider.meta.client_id == "abc123"
      assert provider.meta.market == "US"
      assert Map.has_key?(provider.meta, :expires_at)
    end

    test "supports different provider types" do
      spotify = Provider.new(:spotify)
      apple_music = Provider.new(:apple_music)
      youtube = Provider.new(:youtube)

      assert spotify.id == :spotify
      assert apple_music.id == :apple_music
      assert youtube.id == :youtube
    end
  end

  describe "Provider.Spotify behaviour" do
    alias Songy.Core.Provider.Spotify

    test "meta/1 adds expires_at to credentials" do
      credentials = %{access_token: "abc123", refresh_token: "def456"}

      enhanced = Spotify.meta(credentials)

      assert enhanced.access_token == "abc123"
      assert enhanced.refresh_token == "def456"
      assert %DateTime{} = enhanced.expires_at
      assert DateTime.diff(enhanced.expires_at, DateTime.utc_now(), :second) in 3590..3610
    end

    test "meta/1 preserves existing fields" do
      credentials = %{
        access_token: "token",
        refresh_token: "refresh",
        scope: "user-read-private",
        token_type: "Bearer"
      }

      enhanced = Spotify.meta(credentials)

      assert enhanced.access_token == "token"
      assert enhanced.refresh_token == "refresh"
      assert enhanced.scope == "user-read-private"
      assert enhanced.token_type == "Bearer"
      assert Map.has_key?(enhanced, :expires_at)
    end

    test "meta/1 handles struct input by converting to map" do
      credentials = %TestCredentials{
        access_token: "struct_token",
        refresh_token: "struct_refresh",
        scope: "user-read-private",
        token_type: "Bearer"
      }

      enhanced = Spotify.meta(credentials)

      # Should be converted to map and have expires_at added
      assert is_map(enhanced)
      refute is_struct(enhanced)
      assert enhanced.access_token == "struct_token"
      assert enhanced.refresh_token == "struct_refresh"
      assert enhanced.scope == "user-read-private"
      assert enhanced.token_type == "Bearer"
      assert Map.has_key?(enhanced, :expires_at)
    end

    test "meta/1 handles map input directly" do
      credentials = %{
        access_token: "map_token",
        refresh_token: "map_refresh",
        scope: "user-read-private",
        token_type: "Bearer"
      }

      enhanced = Spotify.meta(credentials)

      # Should keep as map and have expires_at added
      assert is_map(enhanced)
      refute is_struct(enhanced)
      assert enhanced.access_token == "map_token"
      assert enhanced.refresh_token == "map_refresh"
      assert enhanced.scope == "user-read-private"
      assert enhanced.token_type == "Bearer"
      assert Map.has_key?(enhanced, :expires_at)
    end
  end
end
