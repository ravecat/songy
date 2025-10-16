defmodule Songy.Core.Track.Apple do
  @moduledoc """
  Represents an Apple Music track structure.

  This struct mirrors the Apple Music API song resource format with top-level
  fields (id, type, href) and a nested attributes map containing song metadata.

  Unlike Spotify.Track which has a flat structure, Apple Music uses a nested
  attributes object following JSON:API specification.

  ## Structure

  The Apple Music API returns songs in the following format:

      %{
        "id" => "1234567890",
        "type" => "songs",
        "href" => "/v1/catalog/us/songs/1234567890",
        "attributes" => %{
          "name" => "Song Name",
          "artistName" => "Artist Name",
          "albumName" => "Album Name",
          "releaseDate" => "2020-01-01",
          "artwork" => %{
            "url" => "https://is1-ssl.mzstatic.com/image/{w}x{h}bb.jpg"
          },
          "playParams" => %{"id" => "1234567890", "kind" => "song"}
        }
      }

  This struct preserves the original structure with attributes as a map,
  avoiding deep deserialization and potential atom leak issues.
  """

  defstruct [
    :id,
    :type,
    :href,
    :attributes
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          href: String.t(),
          attributes: map()
        }

  @doc """
  Converts a map with string keys to Track.Apple struct.

  Takes a map returned from Apple Music API and converts it to a struct,
  safely handling string-keyed maps by iterating over known struct fields.

  ## Parameters

    * `attrs` - Map with string keys from Apple Music API response

  ## Returns

    * `Track.Apple.t()` - Struct with populated fields

  ## Examples

      iex> to_struct(%{"id" => "123", "type" => "songs", "attributes" => %{"name" => "Test"}})
      %Track.Apple{id: "123", type: "songs", attributes: %{"name" => "Test"}}

  """
  @spec to_struct(map()) :: t()
  def to_struct(attrs) when is_map(attrs) do
    struct = struct(__MODULE__)

    struct
    |> Map.to_list()
    |> Enum.reduce(struct, fn {key, _}, acc ->
      result = Map.fetch(attrs, Atom.to_string(key))

      case result do
        {:ok, value} -> %{acc | key => value}
        :error -> acc
      end
    end)
  end
end
