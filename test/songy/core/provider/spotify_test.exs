defmodule Songy.Core.Provider.SpotifyTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Provider.Spotify

  describe "new/1" do
    test "creates Spotify provider struct from map with all fields" do
      attrs = %{
        access_token: "test_access_token",
        refresh_token: "test_refresh_token",
        device_id: "test_device_id"
      }

      result = Spotify.new(attrs)

      assert %Spotify{} = result
      assert result.access_token == "test_access_token"
      assert result.refresh_token == "test_refresh_token"
      assert result.device_id == "test_device_id"
      assert %DateTime{} = result.expires_at
      assert DateTime.compare(result.expires_at, DateTime.utc_now()) == :gt
    end

    test "creates Spotify provider struct from keyword list" do
      attrs = [
        access_token: "keyword_access_token",
        refresh_token: "keyword_refresh_token",
        device_id: "keyword_device_id"
      ]

      result = Spotify.new(attrs)

      assert %Spotify{} = result
      assert result.access_token == "keyword_access_token"
      assert result.refresh_token == "keyword_refresh_token"
      assert result.device_id == "keyword_device_id"
      assert %DateTime{} = result.expires_at
    end

    test "sets expires_at 3600 seconds in the future" do
      fixed_now = ~U[2024-01-01 12:00:00Z]
      expected_expires_at = DateTime.add(fixed_now, 3600, :second)

      Repatch.patch(DateTime, :utc_now, fn -> fixed_now end)

      attrs = %{
        access_token: "test_access_token",
        refresh_token: "test_refresh_token"
      }

      result = Spotify.new(attrs)

      assert result.expires_at == expected_expires_at
    end
  end

  describe "update/2" do
    test "updates existing Spotify provider struct with new attributes from map" do
      provider =
        Spotify.new(%{
          access_token: "original_access_token",
          refresh_token: "original_refresh_token",
          device_id: "original_device_id"
        })

      attrs = %{
        access_token: "updated_access_token",
        device_id: "updated_device_id"
      }

      result = Spotify.update(provider, attrs)

      assert %Spotify{} = result
      assert result.access_token == "updated_access_token"
      assert result.refresh_token == "original_refresh_token"
      assert result.device_id == "updated_device_id"
      assert %DateTime{} = result.expires_at
      assert DateTime.compare(result.expires_at, DateTime.utc_now()) == :gt
    end

    test "updates existing Spotify provider struct with new attributes from keyword list" do
      provider =
        Spotify.new(%{
          access_token: "original_access_token",
          refresh_token: "original_refresh_token",
          device_id: nil
        })

      attrs = [
        refresh_token: "updated_refresh_token",
        device_id: "new_device_id"
      ]

      result = Spotify.update(provider, attrs)

      assert %Spotify{} = result
      assert result.access_token == "original_access_token"
      assert result.refresh_token == "updated_refresh_token"
      assert result.device_id == "new_device_id"
      assert %DateTime{} = result.expires_at
    end

    test "preserves expires_at when updating non-token fields" do
      initial_fixed_time = ~U[2024-01-01 12:00:00Z]
      initial_expected_expires_at = DateTime.add(initial_fixed_time, 3600, :second)

      Repatch.patch(DateTime, :utc_now, fn -> initial_fixed_time end)

      provider =
        Spotify.new(%{
          access_token: "test_access_token",
          refresh_token: "test_refresh_token"
        })

      assert provider.expires_at == initial_expected_expires_at

      # Update at different time - repatch with force
      update_fixed_time = ~U[2024-01-01 14:00:00Z]

      Repatch.patch(DateTime, :utc_now, [force: true], fn -> update_fixed_time end)

      result = Spotify.update(provider, %{device_id: "new_device"})

      # expires_at should NOT change when updating device_id
      assert result.expires_at == initial_expected_expires_at
      assert result.device_id == "new_device"
    end

    test "recalculates expires_at when updating access_token" do
      initial_fixed_time = ~U[2024-01-01 12:00:00Z]
      initial_expected_expires_at = DateTime.add(initial_fixed_time, 3600, :second)

      Repatch.patch(DateTime, :utc_now, fn -> initial_fixed_time end)

      provider =
        Spotify.new(%{
          access_token: "test_access_token",
          refresh_token: "test_refresh_token"
        })

      assert provider.expires_at == initial_expected_expires_at

      # Update at different time - repatch with force
      update_fixed_time = ~U[2024-01-01 14:00:00Z]
      update_expected_expires_at = DateTime.add(update_fixed_time, 3600, :second)

      Repatch.patch(DateTime, :utc_now, [force: true], fn -> update_fixed_time end)

      result = Spotify.update(provider, %{access_token: "new_access_token"})

      assert result.expires_at == update_expected_expires_at
      assert result.expires_at != provider.expires_at
      assert result.access_token == "new_access_token"
    end
  end
end
