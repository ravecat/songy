defmodule Songy.ProvidersTest do
  use ExUnit.Case, async: true

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

  describe "insert/4" do
    test "inserts new provider data", %{table: table} do
      user_uuid = "user123"
      provider = :apple
      attrs = %{access_token: "token123", refresh_token: "refresh456"}

      assert :ok = Providers.insert(table, user_uuid, provider, attrs)
      assert {:ok, ^attrs} = Providers.lookup(table, user_uuid, provider)
    end

    test "merges with existing provider data", %{table: table} do
      user_uuid = "user123"
      provider = :apple
      initial = %{access_token: "old_token", refresh_token: "refresh456"}
      update = %{access_token: "new_token", device_id: "device789"}
      expected = %{access_token: "new_token", refresh_token: "refresh456", device_id: "device789"}

      assert :ok = Providers.insert(table, user_uuid, provider, initial)
      assert :ok = Providers.insert(table, user_uuid, provider, update)
      assert {:ok, ^expected} = Providers.lookup(table, user_uuid, provider)
    end

    test "handles multiple users and providers", %{table: table} do
      assert :ok = Providers.insert(table, "user1", :apple, %{token: "apple1"})
      assert :ok = Providers.insert(table, "user1", :youtube, %{token: "youtube1"})
      assert :ok = Providers.insert(table, "user2", :apple, %{token: "apple2"})

      assert {:ok, %{token: "apple1"}} = Providers.lookup(table, "user1", :apple)
      assert {:ok, %{token: "youtube1"}} = Providers.lookup(table, "user1", :youtube)
      assert {:ok, %{token: "apple2"}} = Providers.lookup(table, "user2", :apple)
    end
  end

  describe "lookup/3" do
    test "returns not_found for non-existent data", %{table: table} do
      assert {:error, :not_found} = Providers.lookup(table, "user123", :nonexistent)
    end

    test "returns data for existing providers", %{table: table} do
      user_uuid = "user123"
      provider = :apple
      attrs = %{access_token: "token123", refresh_token: "refresh456"}

      assert :ok = Providers.insert(table, user_uuid, provider, attrs)
      assert {:ok, ^attrs} = Providers.lookup(table, user_uuid, provider)
    end

    test "isolates data between users and providers", %{table: table} do
      assert :ok = Providers.insert(table, "user1", :apple, %{token: "apple1"})
      assert :ok = Providers.insert(table, "user1", :youtube, %{token: "youtube1"})
      assert :ok = Providers.insert(table, "user2", :apple, %{token: "apple2"})

      assert {:error, :not_found} = Providers.lookup(table, "user1", :unknown_provider)
      assert {:error, :not_found} = Providers.lookup(table, "unknown_user", :apple)
    end
  end
end
