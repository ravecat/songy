defmodule Songy.Boundary.ProviderTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Provider
  alias Songy.Core.Provider.Spotify

  describe "Provider protocol" do
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
  end

  describe "Spotify provider implementation" do
    test "ensure/1 handles provider with missing refresh_token" do
      spotify_provider = %Spotify{
        access_token: "invalid_token",
        refresh_token: nil
      }

      assert {:error, :authentication_failed} = Provider.ensure(spotify_provider)
    end

    test "ensure/1 delegates to Spotify boundary and handles success" do
      spotify_provider = %Spotify{
        access_token: "token",
        refresh_token: "refresh_token",
        expires_at: DateTime.utc_now()
      }

      updated_provider = %Spotify{
        access_token: "new_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.utc_now()
      }

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure_provider_data, fn _provider ->
        {:ok, updated_provider}
      end)

      assert {:ok, %Spotify{access_token: "new_token"}} = Provider.ensure(spotify_provider)
    end

    test "ensure/1 handles Spotify boundary errors correctly" do
      spotify_provider = %Spotify{
        access_token: "token",
        refresh_token: "refresh_token"
      }

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure_provider_data, fn _provider ->
        {:error, :refresh_failed}
      end)

      assert {:error, :refresh_failed} = Provider.ensure(spotify_provider)
    end

    test "ensure/1 preserves all Spotify provider fields" do
      original_provider = %Spotify{
        access_token: "token",
        refresh_token: "refresh",
        expires_at: DateTime.utc_now(),
        device_id: "device123"
      }

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure_provider_data, fn provider ->
        {:ok, provider}
      end)

      assert {:ok, %Spotify{} = result} = Provider.ensure(original_provider)
      assert result.access_token == original_provider.access_token
      assert result.refresh_token == original_provider.refresh_token
      assert result.device_id == original_provider.device_id
    end
  end

  describe "Protocol pattern matching" do
    test "ensure/1 dispatches correctly based on struct type" do
      spotify_provider = %Spotify{access_token: "token", refresh_token: "refresh"}
      unsupported_provider = %{custom: "provider"}

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure_provider_data, fn provider ->
        {:ok, provider}
      end)

      # Spotify should use specific implementation
      assert {:ok, %Spotify{}} = Provider.ensure(spotify_provider)

      # Unsupported should use Any implementation
      assert {:error, :not_supported} = Provider.ensure(unsupported_provider)
    end
  end
end
