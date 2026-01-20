defmodule Songy.Core.Track.ITunes do
  @moduledoc """
  Represents an iTunes Search API track structure.

  The iTunes Search API returns flat track objects with camelCase keys.
  This struct keeps only fields needed to normalize into Songy.Core.Track
  while preserving the original API field names.
  """

  defstruct [
    :artistName,
    :trackName,
    :previewUrl,
    :artworkUrl30,
    :artworkUrl60,
    :artworkUrl100,
    :releaseDate
  ]

  @type t :: %__MODULE__{
          artistName: String.t() | nil,
          trackName: String.t() | nil,
          previewUrl: String.t() | nil,
          artworkUrl30: String.t() | nil,
          artworkUrl60: String.t() | nil,
          artworkUrl100: String.t() | nil,
          releaseDate: String.t() | nil
        }

  @doc """
  Converts a map with string keys from iTunes Search API to Track.ITunes struct.

  This keeps API field names as-is (camelCase) to avoid extra mapping.
  """
  @spec to_struct(map()) :: t()
  def to_struct(attrs) when is_map(attrs) do
    struct = struct(__MODULE__)

    struct
    |> Map.to_list()
    |> Enum.reduce(struct, fn {key, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(key)) do
        {:ok, value} -> %{acc | key => value}
        :error -> acc
      end
    end)
  end
end
