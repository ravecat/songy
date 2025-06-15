defmodule Songy.Core.ProviderTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Provider

  describe "Provider.new/2" do
    test "creates provider with id only" do
      provider = Provider.new(:spotify)

      assert %Provider{} = provider
      assert provider.id == :spotify
      assert provider.meta == %{}
    end

    test "creates provider with id and meta" do
      meta = %{client_id: "abc123", market: "US"}
      provider = Provider.new(:spotify, meta)

      assert provider.id == :spotify
      assert provider.meta == meta
    end

    test "supports different provider types" do
      spotify = Provider.new(:spotify)
      apple_music = Provider.new(:apple_music)
      youtube = Provider.new(:youtube)

      assert spotify.id == :spotify
      assert apple_music.id == :apple_music
      assert youtube.id == :youtube
    end
  end
end
