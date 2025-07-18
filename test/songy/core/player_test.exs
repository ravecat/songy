defmodule Songy.Core.PlayerTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Player

  describe "new/0" do
    test "creates player with default state" do
      player = Player.new()

      assert %Player{} = player
      assert player.is_playback == false
    end
  end

  describe "toggle_playback/1" do
    test "toggles playback from false to true" do
      player = Player.new()

      toggled_player = Player.toggle_playback(player)

      assert toggled_player.is_playback == true
    end

    test "toggles playback from true to false" do
      player = %Player{is_playback: true}

      toggled_player = Player.toggle_playback(player)

      assert toggled_player.is_playback == false
    end
  end

  describe "set_playback/2" do
    test "sets playback to true" do
      player = Player.new()

      updated_player = Player.set_playback(player, true)

      assert updated_player.is_playback == true
    end

    test "sets playback to false" do
      player = %Player{is_playback: true}

      updated_player = Player.set_playback(player, false)

      assert updated_player.is_playback == false
    end
  end

  describe "playing?/1" do
    test "returns false for new player" do
      player = Player.new()

      assert Player.playing?(player) == false
    end

    test "returns true when playback is active" do
      player = %Player{is_playback: true}

      assert Player.playing?(player) == true
    end

    test "returns false when playback is inactive" do
      player = %Player{is_playback: false}

      assert Player.playing?(player) == false
    end
  end

  describe "JSON encoding" do
    test "encodes player to JSON correctly" do
      player = %Player{is_playback: true}

      encoded = Jason.encode!(player)

      assert encoded == ~s({"is_playback":true})
    end

    test "encodes default player to JSON correctly" do
      player = Player.new()

      encoded = Jason.encode!(player)

      assert encoded == ~s({"is_playback":false})
    end
  end
end
