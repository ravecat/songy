defmodule Songy.Core.TrackTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Track

  describe "new/1" do
    test "creates track with required attributes" do
      track =
        Track.new(
          title: "Bohemian Rhapsody",
          artist: "Queen",
          year: 1975
        )

      assert %Track{} = track
      assert track.title == "Bohemian Rhapsody"
      assert track.artist == "Queen"
      assert track.year == 1975
      assert track.cover_url == nil
    end

    test "creates track with optional cover_url" do
      track =
        Track.new(
          title: "Another One Bites the Dust",
          artist: "Queen",
          year: 1980,
          cover_url: "https://i.scdn.co/image/example123456"
        )

      assert track.cover_url == "https://i.scdn.co/image/example123456"
    end

    test "creates track with nil title" do
      track = Track.new(title: nil, artist: "Queen", year: 1975)

      assert %Track{} = track
      assert track.title == nil
      assert track.artist == "Queen"
      assert track.year == 1975
    end

    test "creates track with nil artist" do
      track = Track.new(title: "Bohemian Rhapsody", artist: nil, year: 1975)

      assert %Track{} = track
      assert track.title == "Bohemian Rhapsody"
      assert track.artist == nil
      assert track.year == 1975
    end

    test "creates track with nil year" do
      track = Track.new(title: "Bohemian Rhapsody", artist: "Queen", year: nil)

      assert %Track{} = track
      assert track.title == "Bohemian Rhapsody"
      assert track.artist == "Queen"
      assert track.year == nil
    end

    test "creates track with all nil values" do
      track = Track.new(title: nil, artist: nil, year: nil)

      assert %Track{} = track
      assert track.title == nil
      assert track.artist == nil
      assert track.year == nil
      assert track.cover_url == nil
    end
  end
end
