defmodule Songy.Core.TrackTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Track

  describe "new/1" do
    test "creates track with required attributes" do
      track =
        Track.new(
          id: "spotify:track:4uLU6hMCjMI75M1A2tKUQC",
          title: "Bohemian Rhapsody",
          artist: "Queen",
          year: 1975
        )

      assert %Track{} = track
      assert track.id == "spotify:track:4uLU6hMCjMI75M1A2tKUQC"
      assert track.title == "Bohemian Rhapsody"
      assert track.artist == "Queen"
      assert track.year == 1975
      assert track.preview_url == nil
    end

    test "creates track with optional preview_url" do
      track =
        Track.new(
          id: "spotify:track:3n3Ppam7vgaVa1iaRUc9Lp",
          title: "Another One Bites the Dust",
          artist: "Queen",
          year: 1980,
          preview_url: "https://p.scdn.co/mp3-preview/123456"
        )

      assert track.preview_url == "https://p.scdn.co/mp3-preview/123456"
    end
  end

  describe "Track.new/1" do
    test "creates track with keyword arguments" do
      track =
        Track.new(
          id: "track123",
          title: "Test Track",
          artist: "Test Artist",
          year: 1980
        )

      assert %Track{} = track
      assert track.id == "track123"
      assert track.title == "Test Track"
      assert track.artist == "Test Artist"
      assert track.year == 1980
      assert track.preview_url == nil
    end
  end
end
