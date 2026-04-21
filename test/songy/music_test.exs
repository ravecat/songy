defmodule Songy.MusicTest do
  use ExUnit.Case, async: true

  alias Songy.Core.Provider.Apple
  alias Songy.Core.Track
  alias Songy.Music
  alias Songy.Provider.Session

  describe "search_cover_tracks/1" do
    test "delegates to provider cover-track strategy" do
      expected_tracks = [%Track{id: "track", title: "Song", artist: "Artist", year: 2024, meta: %{}}]

      Repatch.patch(Songy.Providers, :ensure, fn _user_id ->
        {:ok, Session.normalize!(%Apple{})}
      end)

      Repatch.patch(Songy.Boundary.Provider, :search_cover_tracks, fn %Session{id: :apple} ->
        {:ok, expected_tracks}
      end)

      assert Music.search_cover_tracks("user-1") == expected_tracks
    end

    test "returns empty list when provider resolution fails" do
      Repatch.patch(Songy.Providers, :ensure, fn _user_id ->
        {:error, :not_found}
      end)

      assert Music.search_cover_tracks("user-1") == []
    end
  end
end
