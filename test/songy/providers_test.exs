defmodule Songy.ProvidersTest do
  use ExUnit.Case, async: false

  alias Songy.Core.Provider.Apple
  alias Songy.Core.Provider.Spotify
  alias Songy.Provider.Session
  alias Songy.Providers

  setup do
    if Process.whereis(Providers) == nil do
      _ = start_supervised!(Providers)
    end

    :ok = Providers.clear()
    :ok
  end

  describe "init/1" do
    test "creates ETS table with correct options" do
      table_info = :ets.info(Providers)

      assert table_info[:type] == :set
      assert table_info[:protection] == :protected
      assert table_info[:read_concurrency] == true
    end
  end

  describe "insert/2" do
    test "inserts new provider data" do
      user_id = "user123"

      data = %Spotify{
        access_token: "token123",
        refresh_token: "refresh456",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(user_id, data)
      assert {:ok, %Session{data: %Spotify{} = result}} = Providers.lookup(user_id)
      assert result.access_token == data.access_token
      assert result.refresh_token == data.refresh_token
      assert result.device_id == data.device_id
    end

    test "replaces existing provider data" do
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

      assert :ok = Providers.insert(user_id, initial_data)
      assert :ok = Providers.insert(user_id, new_data)
      assert {:ok, %Session{data: %Spotify{} = result}} = Providers.lookup(user_id)
      assert result.access_token == new_data.access_token
      assert result.device_id == new_data.device_id
    end

    test "handles multiple users with different providers" do
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

      assert :ok = Providers.insert("user1", data1)
      assert :ok = Providers.insert("user2", data2)
      assert :ok = Providers.insert("user3", data3)

      assert {:ok, %Session{data: %Spotify{access_token: "token1"}}} = Providers.lookup("user1")
      assert {:ok, %Session{data: %Spotify{access_token: "token2"}}} = Providers.lookup("user2")
      assert {:ok, %Session{data: %Spotify{access_token: "token3"}}} = Providers.lookup("user3")
    end

    test "replaces provider when user switches to different provider" do
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

      assert :ok = Providers.insert(user_id, initial_data)
      assert {:ok, %Session{data: %Spotify{access_token: "apple_token"}}} = Providers.lookup(user_id)

      assert :ok = Providers.insert(user_id, new_data)
      assert {:ok, %Session{data: %Spotify{access_token: "soundcloud_token"}}} = Providers.lookup(user_id)
    end
  end

  describe "update/2" do
    test "replaces provider data completely" do
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

      assert :ok = Providers.insert(user_id, initial_data)
      assert :ok = Providers.update(user_id, new_data)
      assert {:ok, %Session{data: %Spotify{} = result}} = Providers.lookup(user_id)
      assert result.access_token == new_data.access_token
      assert result.device_id == new_data.device_id
    end

    test "handles update when user has no existing data" do
      user_id = "user123"

      new_data = %Spotify{
        access_token: "test_token",
        refresh_token: "test_refresh",
        device_id: "device789",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.update(user_id, new_data)
      assert {:ok, %Session{data: %Spotify{device_id: "device789"}}} = Providers.lookup(user_id)
    end

    test "handles update when user switches provider" do
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

      assert :ok = Providers.insert(user_id, initial_data)
      assert :ok = Providers.update(user_id, new_data)
      assert {:ok, %Session{data: %Spotify{} = result}} = Providers.lookup(user_id)
      assert result.access_token == new_data.access_token
      assert result.device_id == new_data.device_id
    end
  end

  describe "lookup/1" do
    test "returns not_found for non-existent data" do
      assert {:error, :not_found} = Providers.lookup("user123")
    end

    test "returns data for existing providers" do
      user_id = "user123"

      data = %Spotify{
        access_token: "token123",
        refresh_token: "refresh456",
        device_id: "test_device",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert :ok = Providers.insert(user_id, data)
      assert {:ok, %Session{data: %Spotify{} = result}} = Providers.lookup(user_id)
      assert result.access_token == data.access_token
      assert result.refresh_token == data.refresh_token
    end

    test "isolates data between users" do
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

      assert :ok = Providers.insert("user1", data1)
      assert :ok = Providers.insert("user2", data2)

      assert {:ok, %Session{data: %Spotify{access_token: "token1"}}} = Providers.lookup("user1")
      assert {:ok, %Session{data: %Spotify{access_token: "token2"}}} = Providers.lookup("user2")
      assert {:error, :not_found} = Providers.lookup("unknown_user")
    end

    test "returns current provider regardless of which was inserted" do
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

      assert :ok = Providers.insert(user_id, initial_data)
      assert {:ok, %Session{data: %Spotify{access_token: "apple_token"}}} = Providers.lookup(user_id)

      assert :ok = Providers.insert(user_id, new_data)
      assert {:ok, %Session{data: %Spotify{access_token: "soundcloud_token"}}} = Providers.lookup(user_id)
    end
  end

  describe "ensure/1" do
    test "returns current provider when valid" do
      user_id = "user123"
      current_time = ~U[2025-07-15 12:00:00Z]
      future_expires_at = DateTime.add(current_time, 3600, :second)

      valid_data = %Spotify{
        access_token: "valid_token",
        refresh_token: "valid_refresh",
        device_id: "device2",
        expires_at: future_expires_at
      }

      assert :ok = Providers.insert(user_id, valid_data)

      Repatch.patch(DateTime, :utc_now, fn -> current_time end)

      assert {:ok, %Session{id: :spotify, data: result}} = Providers.ensure(user_id)
      assert result.access_token == "valid_token"
    end

    test "resolves Apple Music from config when user has no persisted provider" do
      user_id = "new_user"

      assert {:ok, %Session{id: :apple, data: %Apple{}}} = Providers.ensure(user_id)
      assert {:error, :not_found} = Providers.lookup(user_id)
    end

    test "ignores a persisted iTunes fallback session and resolves Apple Music from config" do
      user_id = "user_with_stale_itunes_fallback"

      assert :ok = Providers.insert(user_id, %Songy.Core.Provider.ITunes{})

      assert {:ok, %Session{id: :apple, data: %Apple{}}} = Providers.ensure(user_id)
      assert {:error, :not_found} = Providers.lookup(user_id)
    end

    test "updates ETS when token has expired" do
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

      assert :ok = Providers.insert(user_id, expired_data)

      Repatch.patch(DateTime, :utc_now, fn -> current_time end)

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure, fn _provider ->
        {:ok, :spotify, refreshed_data}
      end)

      assert {:ok, %Session{id: :spotify, data: result}} = Providers.ensure(user_id)
      assert result.access_token == "refreshed_token"

      assert [{^user_id, stored_session}] = :ets.lookup(Providers, user_id)
      assert stored_session.data.access_token == "refreshed_token"
    end

    test "falls back to Apple Music from config when credentials are invalid" do
      user_id = "user_with_invalid_refresh"

      invalid_data = %Spotify{
        access_token: "token",
        refresh_token: nil
      }

      assert :ok = Providers.insert(user_id, invalid_data)

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure, fn _provider ->
        {:error, :invalid_credentials}
      end)

      assert {:ok, %Session{id: :apple, data: %Apple{}}} = Providers.ensure(user_id)
      assert {:error, :not_found} = Providers.lookup(user_id)
    end

    test "returns error for transient failures without removing provider" do
      user_id = "user_with_network_error"

      valid_data = %Spotify{
        access_token: "token",
        refresh_token: "refresh",
        expires_at: DateTime.add(DateTime.utc_now(), -3600, :second)
      }

      assert :ok = Providers.insert(user_id, valid_data)

      Repatch.patch(Songy.Boundary.Provider.Spotify, :ensure, fn _provider ->
        {:error, :network_error}
      end)

      assert {:error, :network_error} = Providers.ensure(user_id)
      assert {:ok, %Session{data: %Spotify{}}} = Providers.lookup(user_id)
    end
  end
end
