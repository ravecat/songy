defmodule Songy.Core.ProviderTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Provider

  describe "Provider" do
    test "creates provider without metadata" do
      provider = Provider.new(:spotify)

      assert match?(%Provider{id: :spotify, meta: nil}, provider)
    end

    test "creates provider with metadata" do
      meta = %{device_id: "test_device_123"}
      provider = Provider.new(:spotify, meta)

      assert match?(%Provider{id: :spotify, meta: %Provider.Spotify{device_id: "test_device_123"}}, provider)
    end

    test "returns error for unknown provider" do
      assert {:error, changeset} = Provider.new(:unknown_provider, %{custom: "data"})
      assert %Ecto.Changeset{} = changeset
      assert changeset.valid? == false
    end
  end

  describe "Spotify" do
    test "new/2 creates a new Spotify provider" do
      meta = %{device_id: "test_device"}

      provider = Provider.new(:spotify, meta)

      assert %Provider{} = provider
      assert provider.id == :spotify
      assert provider.meta.device_id == "test_device"
    end

    test "new/2 creates a new Spotify provider with credentials" do
      meta = %{device_id: "test_device", access_token: "test_access", refresh_token: "test_refresh"}

      provider = Provider.new(:spotify, meta)

      assert %Provider{} = provider
      assert provider.id == :spotify
      assert provider.meta.device_id == nil
      assert provider.meta.access_token == "test_access"
      assert provider.meta.refresh_token == "test_refresh"
      assert %DateTime{} = provider.meta.expires_at
      assert DateTime.diff(provider.meta.expires_at, DateTime.utc_now(), :second) in 3590..3610
    end

    test "update/2 updates provider metadata" do
      provider = Provider.new(:spotify, %{device_id: "old_device"})
      patch = %{device_id: "new_device"}

      updated_provider = Provider.update(provider, patch)

      assert %Provider{} = updated_provider
      assert updated_provider.id == :spotify
      assert updated_provider.meta.device_id == "new_device"
    end

    test "update/2 preserves existing metadata when updating" do
      provider =
        Provider.new(:spotify, %{access_token: "old_token", refresh_token: "old_refresh", device_id: "old_device"})

      patch = %{device_id: "new_device"}

      updated_provider = Provider.update(provider, patch)

      assert updated_provider.meta.device_id == "new_device"
      assert updated_provider.meta.access_token == "old_token"
      assert updated_provider.meta.refresh_token == "old_refresh"
    end

    test "update/2 with access token extended with expires_at" do
      credentials = %{access_token: "abc123", refresh_token: "def456"}
      provider = Provider.new(:spotify, %{device_id: "test_device"})

      assert provider.meta.expires_at == nil

      result = Provider.update(provider, credentials)

      assert %Provider{} = result
      assert result.meta.access_token == "abc123"
      assert result.meta.refresh_token == "def456"
      assert %DateTime{} = result.meta.expires_at
      assert DateTime.diff(result.meta.expires_at, DateTime.utc_now(), :second) in 3590..3610
    end

    test "update/2 with empty patch preserves existing data" do
      patch = %{}
      provider = Provider.new(:spotify, %{device_id: "test_device"})

      result = Provider.update(provider, patch)
      assert %Provider{} = result
      assert result.meta.device_id == "test_device"
    end
  end
end
