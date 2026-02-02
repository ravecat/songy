defmodule Songy.Music do
  @moduledoc """
  Music catalog operations.
  """

  alias Songy.Boundary.Provider
  alias Songy.Providers

  @spec fetch_cover_tracks(String.t(), pos_integer()) :: list(map())
  def fetch_cover_tracks(user_id, limit \\ 50) do
    term = <<Enum.random(?a..?z)>>

    with {:ok, _id, provider} <- Providers.ensure(user_id),
         {:ok, tracks} <- Provider.search(provider, term: term, limit: limit, entity: "song") do
      tracks
    else
      _ -> []
    end
  end
end
