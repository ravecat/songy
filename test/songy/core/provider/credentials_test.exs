defmodule Songy.Core.Provider.CredentialsTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Provider
  alias Songy.Core.Provider.{Credentials, Spotify}

  describe "Credentials protocol" do
    test "fetches credentials from Provider with valid Spotify meta" do
      provider = Provider.new(:spotify, %{access_token: "test_token", device_id: "test_device"})

      credentials = Credentials.fetch(provider)

      assert credentials.access_token == "test_token"
    end

    test "returns nil for Provider with nil meta" do
      provider = Provider.new(:spotify)

      assert nil == Credentials.fetch(provider)
    end

    test "fetches credentials from Spotify struct directly" do
      spotify = %Spotify{access_token: "direct_token", refresh_token: "refresh_token"}

      credentials = Credentials.fetch(spotify)

      assert credentials.access_token == "direct_token"
      assert credentials.refresh_token == "refresh_token"
    end

    test "returns nil for Spotify struct without access_token" do
      spotify = %Spotify{refresh_token: "refresh_token"}

      assert nil == Credentials.fetch(spotify)
    end

    test "returns nil for any other structure (fallback)" do
      assert nil == Credentials.fetch(%{some: "data"})
      assert nil == Credentials.fetch("string")
      assert nil == Credentials.fetch(123)
      assert nil == Credentials.fetch([:list])
    end
  end
end
