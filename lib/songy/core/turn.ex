defmodule Songy.Core.Turn do
  @moduledoc """
  Represents an active turn in the music year guessing quiz.

  A turn contains information about the current game state:
  - which player is active
  - which players are challenging to answer
  - what track is currently being played
  """

  use TypedStruct

  alias Songy.Core.Track

  @derive {Jason.Encoder, only: [:player_id, :challengers, :track]}

  typedstruct do
    field :player_id, String.t(), enforce: true
    field :challengers, list(String.t()), default: []
    field :track, Track.t()
  end

  @doc """
  Creates a new turn with the given attributes.

  ## Parameters
    * `attrs` - Keyword list containing turn attributes
      * `:player_id` - UUID of the active player (required)
      * `:challengers` - List of player UUIDs who want to answer (optional, defaults to empty list)
      * `:track` - Current track being played (optional)

  ## Examples
      iex> Turn.new(player_id: "player-uuid-123")
      %Turn{player_id: "player-uuid-123", challengers: [], track: nil}

      iex> Turn.new(player_id: "player-uuid-123", challengers: ["player-uuid-456", "player-uuid-789"])
      %Turn{player_id: "player-uuid-123", challengers: ["player-uuid-456", "player-uuid-789"], track: nil}
  """
  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, attrs)
  end

  @doc """
  Adds a challenger to the turn.

  ## Parameters
    * `turn` - The current turn state
    * `challenger_id` - UUID of the challenger to add

  ## Examples
      iex> turn = Turn.new(player_id: "player-1")
      iex> Turn.add_challenger(turn, "challenger-1")
      %Turn{player_id: "player-1", challengers: ["challenger-1"], track: nil}

      iex> turn = Turn.new(player_id: "player-1", challengers: ["first-challenger"])
      iex> Turn.add_challenger(turn, "second-challenger")
      %Turn{player_id: "player-1", challengers: ["first-challenger", "second-challenger"], track: nil}
  """
  @spec add_challenger(t(), String.t()) :: t()
  def add_challenger(%__MODULE__{} = turn, challenger_id) when is_binary(challenger_id) do
    %{turn | challengers: turn.challengers ++ [challenger_id]}
  end

  @doc """
  Sets the track for the turn.

  ## Parameters
    * `turn` - The current turn state
    * `track` - The track to set

  ## Examples
      iex> turn = Turn.new(player_id: "player-1")
      iex> track = Track.new(id: "track-1", title: "Song", artist: "Artist", year: 2020)
      iex> Turn.set_track(turn, track)
      %Turn{player_id: "player-1", challengers: [], track: %Track{...}}

      iex> turn = Turn.new(player_id: "player-1", track: old_track)
      iex> Turn.set_track(turn, new_track)
      %Turn{player_id: "player-1", challengers: [], track: %Track{...}}
  """
  @spec set_track(t(), Track.t()) :: t()
  def set_track(%__MODULE__{} = turn, %Track{} = track) do
    %{turn | track: track}
  end
end
