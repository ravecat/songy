defmodule Songy.Core.Provider.SpotifyTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Provider

  describe "Provider.new/2 for spotify" do
    test "returns provider struct" do
      attrs = %{
        access_token: "access_token",
        refresh_token: "refresh_token"
      }

      result = Provider.new(:spotify, attrs)

      assert match?(
               %Provider{
                 id: :spotify,
                 meta: %Provider.Spotify{
                   access_token: "access_token",
                   refresh_token: "refresh_token"
                 }
               },
               result
             )
    end

    test "returns provider struct with exact auth fields" do
      fixed_time = ~U[2025-07-15 12:00:00Z]
      expected_expiry = DateTime.add(fixed_time, 3600, :second)

      Repatch.patch(DateTime, :utc_now, fn -> fixed_time end)

      attrs = %{
        access_token: "access_token",
        refresh_token: "refresh_token",
        extra_field: "extra_value",
        device_id: "device_id"
      }

      result = Provider.new(:spotify, attrs)

      assert match?(
               %Provider{
                 id: :spotify,
                 meta: %Provider.Spotify{
                   access_token: "access_token",
                   refresh_token: "refresh_token",
                   expires_at: ^expected_expiry,
                   device_id: nil
                 }
               },
               result
             )
    end

    test "returns provider struct with excluded auth fields" do
      attrs = %{
        extra_field: "extra_value",
        device_id: "device_id"
      }

      result = Provider.new(:spotify, attrs)

      assert match?(
               %Provider{
                 id: :spotify,
                 meta: %Provider.Spotify{
                   access_token: nil,
                   refresh_token: nil,
                   expires_at: nil,
                   device_id: "device_id"
                 }
               },
               result
             )
    end
  end

  describe "Provider.update/2 for spotify" do
    test "updates provider with auth data" do
      provider = Provider.new(:spotify, %{device_id: "initial_device"})

      attrs = %{
        access_token: "new_access_token",
        refresh_token: "new_refresh_token"
      }

      result = Provider.update(provider, attrs)

      assert match?(
               %Provider{
                 id: :spotify,
                 meta: %Provider.Spotify{
                   access_token: "new_access_token",
                   refresh_token: "new_refresh_token",
                   device_id: "initial_device"
                 }
               },
               result
             )
    end

    test "updates provider with exact auth fields" do
      fixed_time = ~U[2025-07-15 12:00:00Z]
      expected_expiry = DateTime.add(fixed_time, 3600, :second)

      Repatch.patch(DateTime, :utc_now, fn -> fixed_time end)

      provider = Provider.new(:spotify, %{device_id: "initial_device"})

      attrs = %{
        access_token: "new_access_token",
        refresh_token: "new_refresh_token",
        extra_field: "extra_value"
      }

      result = Provider.update(provider, attrs)

      assert match?(
               %Provider{
                 id: :spotify,
                 meta: %Provider.Spotify{
                   access_token: "new_access_token",
                   refresh_token: "new_refresh_token",
                   expires_at: ^expected_expiry,
                   device_id: "initial_device"
                 }
               },
               result
             )
    end

    test "updates provider with whitelisted fields only" do
      provider =
        Provider.new(:spotify, %{
          access_token: "existing_token",
          refresh_token: "existing_refresh"
        })

      attrs = %{
        device_id: "new_device_id",
        extra_field: "extra_value"
      }

      result = Provider.update(provider, attrs)

      assert match?(
               %Provider{
                 id: :spotify,
                 meta: %Provider.Spotify{
                   access_token: "existing_token",
                   refresh_token: "existing_refresh",
                   device_id: "new_device_id"
                 }
               },
               result
             )
    end
  end
end
