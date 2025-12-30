defmodule Songy.ProvidersTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Provider.Spotify
  alias Songy.Providers

  setup context do
    _ = start_supervised!({Providers, name: context.test})

    %{table: context.test}
  end

  describe "init/1" do
    test "creates ETS table with correct options", %{table: table} do
      table_info = :ets.info(table)

      assert table_info[:type] == :set
      assert table_info[:protection] == :protected
      assert table_info[:read_concurrency] == true
    end
  end

  describe "insert/3" do
    test "inserts new provider data", %{table: table} do
      user_id = "user123"

      data = %Spotify{
        access_token: "token123",
        refresh_token: "refresh456",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(table, user_id, data)
      assert {:ok, %Spotify{} = result} = Providers.lookup(table, user_id)
      assert result.access_token == data.access_token
      assert result.refresh_token == data.refresh_token
      assert result.device_id == data.device_id
    end

    test "replaces existing provider data", %{table: table} do
      user_id = "user123"

      initial_data = %Spotify{
        access_token: "old_token",
        refresh_token: "refresh456",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      new_data = %Spotify{
        access_token: "new_token",
        refresh_token: "refresh456",
        device_id: "device789",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(table, user_id, initial_data)
      assert :ok = Providers.insert(table, user_id, new_data)
      assert {:ok, %Spotify{} = result} = Providers.lookup(table, user_id)
      assert result.access_token == new_data.access_token
      assert result.device_id == new_data.device_id
    end

    test "handles multiple users with different providers", %{table: table} do
      data1 = %Spotify{
        access_token: "token1",
        refresh_token: "test_refresh",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      data2 = %Spotify{
        access_token: "token2",
        refresh_token: "test_refresh",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      data3 = %Spotify{
        access_token: "token3",
        refresh_token: "test_refresh",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(table, "user1", data1)
      assert :ok = Providers.insert(table, "user2", data2)
      assert :ok = Providers.insert(table, "user3", data3)

      assert {:ok, %Spotify{access_token: "token1"}} = Providers.lookup(table, "user1")
      assert {:ok, %Spotify{access_token: "token2"}} = Providers.lookup(table, "user2")
      assert {:ok, %Spotify{access_token: "token3"}} = Providers.lookup(table, "user3")
    end

    test "replaces provider when user switches to different provider", %{table: table} do
      user_id = "user123"

      initial_data = %Spotify{
        access_token: "apple_token",
        refresh_token: "test_refresh",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      new_data = %Spotify{
        access_token: "soundcloud_token",
        refresh_token: "test_refresh",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(table, user_id, initial_data)
      assert {:ok, %Spotify{access_token: "apple_token"}} = Providers.lookup(table, user_id)

      assert :ok = Providers.insert(table, user_id, new_data)
      assert {:ok, %Spotify{access_token: "soundcloud_token"}} = Providers.lookup(table, user_id)
    end
  end

  describe "update/3" do
    test "replaces provider data completely", %{table: table} do
      user_id = "user123"

      initial_data = %Spotify{
        access_token: "old_token",
        refresh_token: "refresh456",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      new_data = %Spotify{
        access_token: "new_token",
        refresh_token: "refresh456",
        device_id: "device789",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(table, user_id, initial_data)
      assert :ok = Providers.update(table, user_id, new_data)
      assert {:ok, %Spotify{} = result} = Providers.lookup(table, user_id)
      assert result.access_token == new_data.access_token
      assert result.device_id == new_data.device_id
    end

    test "handles update when user has no existing data", %{table: table} do
      user_id = "user123"

      new_data = %Spotify{
        access_token: "test_token",
        refresh_token: "test_refresh",
        device_id: "device789",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.update(table, user_id, new_data)
      assert {:ok, %Spotify{device_id: "device789"}} = Providers.lookup(table, user_id)
    end

    test "handles update when user switches provider", %{table: table} do
      user_id = "user123"

      initial_data = %Spotify{
        access_token: "apple_token",
        refresh_token: "test_refresh",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      new_data = %Spotify{
        access_token: "soundcloud_token",
        refresh_token: "test_refresh",
        device_id: "device789",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(table, user_id, initial_data)
      assert :ok = Providers.update(table, user_id, new_data)
      assert {:ok, %Spotify{} = result} = Providers.lookup(table, user_id)
      assert result.access_token == new_data.access_token
      assert result.device_id == new_data.device_id
    end
  end

  describe "lookup/2" do
    test "returns not_found for non-existent data", %{table: table} do
      assert {:error, :not_found} = Providers.lookup(table, "user123")
    end

    test "returns data for existing providers", %{table: table} do
      user_id = "user123"

      data = %Spotify{
        access_token: "token123",
        refresh_token: "refresh456",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(table, user_id, data)
      assert {:ok, %Spotify{} = result} = Providers.lookup(table, user_id)
      assert result.access_token == data.access_token
      assert result.refresh_token == data.refresh_token
    end

    test "isolates data between users", %{table: table} do
      data1 = %Spotify{
        access_token: "token1",
        refresh_token: "test_refresh",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      data2 = %Spotify{
        access_token: "token2",
        refresh_token: "test_refresh",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(table, "user1", data1)
      assert :ok = Providers.insert(table, "user2", data2)

      assert {:ok, %Spotify{access_token: "token1"}} = Providers.lookup(table, "user1")
      assert {:ok, %Spotify{access_token: "token2"}} = Providers.lookup(table, "user2")
      assert {:error, :not_found} = Providers.lookup(table, "unknown_user")
    end

    test "returns current provider regardless of which was inserted", %{table: table} do
      user_id = "user123"

      initial_data = %Spotify{
        access_token: "apple_token",
        refresh_token: "test_refresh",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      new_data = %Spotify{
        access_token: "soundcloud_token",
        refresh_token: "test_refresh",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(table, user_id, initial_data)
      assert {:ok, %Spotify{access_token: "apple_token"}} = Providers.lookup(table, user_id)

      assert :ok = Providers.insert(table, user_id, new_data)
      assert {:ok, %Spotify{access_token: "soundcloud_token"}} = Providers.lookup(table, user_id)
    end

    test "updates ETS when token has expired", %{table: table} do
      user_id = "user_with_expired_token"
      current_time = ~U[2025-07-15 12:00:00Z]
      expired_at = DateTime.add(current_time, -3600, :second)

      expired_data = %Spotify{
        access_token: "expired_token",
        refresh_token: "valid_refresh",
        device_id: "device1",
        expires_at: expired_at
      }

      refreshed_data = %Spotify{
        access_token: "refreshed_token",
        refresh_token: "valid_refresh",
        device_id: "device1",
        expires_at: DateTime.add(current_time, 3600, :second)
      }

      assert :ok = Providers.insert(table, user_id, expired_data)

      Repatch.patch(DateTime, :utc_now, fn -> current_time end)

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure_provider_data, fn _provider ->
        {:ok, refreshed_data}
      end)

      assert {:ok, result} = Providers.lookup(table, user_id)
      assert result.access_token == "refreshed_token"

      assert [{^user_id, stored_data}] = :ets.lookup(table, user_id)
      assert stored_data.access_token == "refreshed_token"
    end

    test "does not update ETS when token is still valid", %{table: table} do
      user_id = "user_with_valid_token"
      current_time = ~U[2025-07-15 12:00:00Z]
      future_expires_at = DateTime.add(current_time, 3600, :second)

      valid_data = %Spotify{
        access_token: "valid_token",
        refresh_token: "valid_refresh",
        device_id: "device2",
        expires_at: future_expires_at
      }

      assert :ok = Providers.insert(table, user_id, valid_data)

      Repatch.patch(DateTime, :utc_now, fn -> current_time end)

      assert {:ok, result} = Providers.lookup(table, user_id)
      assert result.access_token == "valid_token"

      assert [{^user_id, stored_data}] = :ets.lookup(table, user_id)
      assert stored_data.access_token == "valid_token"
    end

    test "returns refreshed token even when ETS not updated yet", %{table: table} do
      user_id = "user_simultaneous_refresh"
      current_time = ~U[2025-07-15 12:00:00Z]
      expired_at = DateTime.add(current_time, -60, :second)

      expired_data = %Spotify{
        access_token: "expired_token",
        refresh_token: "valid_refresh",
        expires_at: expired_at
      }

      refreshed_data = %Spotify{
        access_token: "fresh_token",
        refresh_token: "valid_refresh",
        expires_at: DateTime.add(current_time, 3600, :second)
      }

      assert :ok = Providers.insert(table, user_id, expired_data)

      Repatch.patch(DateTime, :utc_now, fn -> current_time end)

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure_provider_data, fn _provider ->
        {:ok, refreshed_data}
      end)

      assert {:ok, result} = Providers.lookup(table, user_id)
      assert result.access_token == "fresh_token"
    end

    test "handles ensure error by removing from ETS", %{table: table} do
      user_id = "user_with_invalid_refresh"

      invalid_data = %Spotify{
        access_token: "token",
        refresh_token: nil
      }

      assert :ok = Providers.insert(table, user_id, invalid_data)

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure_provider_data, fn _provider ->
        {:error, :authentication_failed}
      end)

      assert {:error, :authentication_failed} = Providers.lookup(table, user_id)

      assert [] = :ets.lookup(table, user_id)
    end
  end
end
