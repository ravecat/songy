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
  end
end
