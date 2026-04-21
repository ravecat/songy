defmodule Songy.Boundary.ProviderTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Provider
  alias Songy.Core.Provider.Spotify
  alias Songy.Provider.Session

  describe "provider facade / unknown" do
    test "ensure/1 returns error for unsupported provider types" do
      unsupported_provider = %{type: :unknown}

      assert {:error, :not_supported} = Provider.ensure(unsupported_provider)
    end

    test "ensure/1 returns error for nil provider" do
      assert {:error, :not_supported} = Provider.ensure(nil)
    end

    test "ensure/1 returns error for string provider" do
      assert {:error, :not_supported} = Provider.ensure("not_a_provider")
    end

    test "ensure/1 returns error for atom provider" do
      assert {:error, :not_supported} = Provider.ensure(:invalid_provider)
    end

    test "search_cover_tracks/1 returns error for unsupported provider types" do
      assert {:error, :not_supported} = Provider.search_cover_tracks(nil)
    end
  end

  describe "provider facade / spotify" do
    test "ensure/1 handles provider with missing refresh_token" do
      spotify_provider =
        Session.normalize!(%Spotify{
          access_token: "invalid_token",
          refresh_token: nil
        })

      assert {:error, :authentication_failed} = Provider.ensure(spotify_provider)
    end

    test "ensure/1 delegates to Spotify boundary and handles success" do
      spotify_provider =
        Session.normalize!(%Spotify{
          access_token: "token",
          refresh_token: "refresh_token",
          expires_at: DateTime.utc_now()
        })

      updated_provider = %Spotify{
        access_token: "new_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.utc_now()
      }

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure, fn _provider ->
        {:ok, :spotify, updated_provider}
      end)

      assert {:ok, %Session{id: :spotify, data: %Spotify{access_token: "new_token"}}} =
               Provider.ensure(spotify_provider)
    end

    test "ensure/1 handles Spotify boundary errors correctly" do
      spotify_provider =
        Session.normalize!(%Spotify{
          access_token: "token",
          refresh_token: "refresh_token"
        })

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure, fn _provider ->
        {:error, :refresh_failed}
      end)

      assert {:error, :refresh_failed} = Provider.ensure(spotify_provider)
    end

    test "ensure/1 preserves all Spotify provider fields" do
      original_provider =
        Session.normalize!(%Spotify{
          access_token: "token",
          refresh_token: "refresh",
          expires_at: DateTime.utc_now(),
          device_id: "device123"
        })

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure, fn provider ->
        {:ok, :spotify, provider}
      end)

      assert {:ok, %Session{id: :spotify, data: %Spotify{} = result}} = Provider.ensure(original_provider)
      assert result.access_token == original_provider.data.access_token
      assert result.refresh_token == original_provider.data.refresh_token
      assert result.device_id == original_provider.data.device_id
    end

    test "search_cover_tracks/1 delegates to Spotify boundary" do
      spotify_provider =
        Session.normalize!(%Spotify{
          access_token: "token",
          refresh_token: "refresh_token",
          expires_at: DateTime.utc_now()
        })

      expected_tracks = [%Songy.Core.Track{id: "track"}]

      Repatch.patch(Songy.Boundary.Provider.Spotify, :search_cover_tracks, fn _provider ->
        {:ok, expected_tracks}
      end)

      assert {:ok, ^expected_tracks} = Provider.search_cover_tracks(spotify_provider)
    end
  end
end
