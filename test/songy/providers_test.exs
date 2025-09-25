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
      user_id = "user123"
      provider = :apple
      attrs = %{access_token: "token123", refresh_token: "refresh456"}

      assert :ok = Providers.insert(table, user_id, provider, attrs)
      assert {:ok, {^provider, ^attrs}} = Providers.lookup(table, user_id)
    end

    test "replaces existing provider data", %{table: table} do
      user_id = "user123"
      initial_attrs = %{access_token: "old_token", refresh_token: "refresh456"}
      new_attrs = %{access_token: "new_token", device_id: "device789"}

      assert :ok = Providers.insert(table, user_id, :apple, initial_attrs)
      assert :ok = Providers.insert(table, user_id, :apple, new_attrs)
      assert {:ok, {:apple, ^new_attrs}} = Providers.lookup(table, user_id)
    end

    test "handles multiple users with different providers", %{table: table} do
      assert :ok = Providers.insert(table, "user1", :apple, %{token: "apple1"})
      assert :ok = Providers.insert(table, "user2", :soundcloud, %{token: "soundcloud2"})
      assert :ok = Providers.insert(table, "user3", :apple, %{token: "apple3"})

      assert {:ok, {:apple, %{token: "apple1"}}} = Providers.lookup(table, "user1")
      assert {:ok, {:soundcloud, %{token: "soundcloud2"}}} = Providers.lookup(table, "user2")
      assert {:ok, {:apple, %{token: "apple3"}}} = Providers.lookup(table, "user3")
    end

    test "replaces provider when user switches to different provider", %{table: table} do
      user_id = "user123"

      assert :ok = Providers.insert(table, user_id, :apple, %{token: "apple_token"})
      assert {:ok, {:apple, %{token: "apple_token"}}} = Providers.lookup(table, user_id)

      assert :ok = Providers.insert(table, user_id, :soundcloud, %{token: "soundcloud_token"})
      assert {:ok, {:soundcloud, %{token: "soundcloud_token"}}} = Providers.lookup(table, user_id)
    end
  end

  describe "lookup/2" do
    test "returns not_found for non-existent data", %{table: table} do
      assert {:error, :not_found} = Providers.lookup(table, "user123")
    end

    test "returns data for existing providers", %{table: table} do
      user_id = "user123"
      provider = :apple
      attrs = %{access_token: "token123", refresh_token: "refresh456"}

      assert :ok = Providers.insert(table, user_id, provider, attrs)
      assert {:ok, {^provider, ^attrs}} = Providers.lookup(table, user_id)
    end

    test "isolates data between users", %{table: table} do
      assert :ok = Providers.insert(table, "user1", :apple, %{token: "apple1"})
      assert :ok = Providers.insert(table, "user2", :apple, %{token: "apple2"})

      assert {:ok, {:apple, %{token: "apple1"}}} = Providers.lookup(table, "user1")
      assert {:ok, {:apple, %{token: "apple2"}}} = Providers.lookup(table, "user2")
      assert {:error, :not_found} = Providers.lookup(table, "unknown_user")
    end

    test "returns current provider regardless of which was inserted", %{table: table} do
      user_id = "user123"

      assert :ok = Providers.insert(table, user_id, :apple, %{token: "apple_token"})
      assert {:ok, {:apple, %{token: "apple_token"}}} = Providers.lookup(table, user_id)

      # User switches to different provider, previous one is replaced
      assert :ok = Providers.insert(table, user_id, :soundcloud, %{token: "soundcloud_token"})
      assert {:ok, {:soundcloud, %{token: "soundcloud_token"}}} = Providers.lookup(table, user_id)
    end
  end
end
