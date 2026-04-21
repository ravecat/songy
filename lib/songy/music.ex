defmodule Songy.Music do
  @moduledoc """
  Music catalog operations.
  """

  alias Songy.Boundary.Provider
  alias Songy.Core.Track
  alias Songy.Providers

  @spec search_cover_tracks(String.t()) :: [Track.t()]
  def search_cover_tracks(user_id) do
    with {:ok, session} <- Providers.ensure(user_id),
         {:ok, tracks} <- Provider.search_cover_tracks(session) do
      tracks
    else
      _ -> []
    end
  end
end
