defmodule Songy.Core.Turn do
  @moduledoc """
  Represents an active turn in the music year guessing quiz.

  A turn contains information about the current game state:
  - which player is active (determined by queue position)
  - which players are challenging to answer
  - what track is currently being played
  - the queue of players and current player index
  """

  use TypedStruct

  alias Songy.Core.Track

  @typep phase :: :waiting | :ready | :steady | :challenging | :results

  @derive {Jason.Encoder, only: [:queue, :cursor, :challengers, :track, :phase, :timeline, :assumptions]}

  typedstruct do
    field :queue, list(String.t()), default: []
    field :cursor, non_neg_integer(), default: 0
    field :challengers, list(String.t()), default: []
    field :track, Track.t()
    field :phase, phase(), default: :waiting
    field :timeline, list(Track.t()), default: []
    field :assumptions, list({non_neg_integer(), String.t()}), default: []
  end

  @doc """
  Creates a new turn with default values.

  ## Examples
      iex> Turn.new()
      %Songy.Core.Turn{queue: [], cursor: 0, challengers: [], track: nil, phase: :waiting}
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Adds a challenger to the turn.

  ## Parameters
    * `turn` - The current turn state
    * `challenger_id` - UUID of the challenger to add

  ## Examples
      ## Examples
      iex> turn = Turn.new() |> Turn.add_player_to_queue("player-1")
      iex> Turn.add_challenger(turn, "challenger-1")
      %Songy.Core.Turn{queue: ["player-1"], cursor: 0, challengers: ["challenger-1"], track: nil}

      iex> turn = Turn.new() |> Turn.add_player_to_queue("player-1") |> Turn.add_challenger("challenger-1")
      iex> Turn.add_challenger(turn, "challenger-2")
      %Songy.Core.Turn{queue: ["player-1"], cursor: 0, challengers: ["challenger-1", "challenger-2"], track: nil}
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
      iex> turn = Turn.with_queue(["player-1"])
      iex> track = Track.new(title: "Song", artist: "Artist", year: 2020)
      iex> Turn.set_track(turn, track)
      %Songy.Core.Turn{queue: ["player-1"], cursor: 0, challengers: [], track: %Track{...}}

      iex> turn = Turn.with_queue(["player-1"]) |> Turn.set_track(old_track)
      iex> Turn.set_track(turn, new_track)
      %Songy.Core.Turn{queue: ["player-1"], cursor: 0, challengers: [], track: %Track{...}}
  """
  @spec set_track(t(), Track.t()) :: t()
  def set_track(%__MODULE__{} = turn, %Track{} = track) do
    %{turn | track: track}
  end

  @doc """
  Gets the track for the current turn.

  Returns the track assigned to this turn for players to guess.

  ## Examples
      iex> track = Track.new(title: "Bohemian Rhapsody", artist: "Queen", year: 1975)
      iex> turn = Turn.new() |> Turn.set_track(track)
      iex> Turn.get_track(turn)
      %Track{title: "Bohemian Rhapsody", artist: "Queen", year: 1975}

      iex> Turn.get_track(Turn.new())
      nil
  """
  @spec get_track(t()) :: Track.t() | nil
  def get_track(%__MODULE__{track: track}), do: track

  @doc """
  Gets the active player from the turn queue.

  ## Parameters
    * `turn` - The current turn state

  ## Returns
    * UUID of the active player or nil if queue is empty

  ## Examples
      iex> turn = Turn.new(queue: ["player-1", "player-2"], cursor: 0)
      iex> Turn.get_active_player(turn)
      "player-1"

      iex> turn = Turn.new(queue: [], cursor: 0)
      iex> Turn.get_active_player(turn)
      nil
  """
  @spec get_active_player(t()) :: String.t() | nil
  def get_active_player(%__MODULE__{queue: queue, cursor: index}) do
    Enum.at(queue, index)
  end

  @doc """
  Adds a player to the end of the queue.

  ## Parameters
    * `turn` - The current turn state
    * `player_uuid` - UUID of the player to add

  ## Examples
      iex> turn = Turn.new(queue: ["player-1"])
      iex> Turn.add_player_to_queue(turn, "player-2")
      %Songy.Core.Turn{queue: ["player-1", "player-2"], cursor: 0, challengers: [], track: nil}
  """
  @spec add_player_to_queue(t(), String.t()) :: t()
  def add_player_to_queue(%__MODULE__{} = turn, player_uuid) when is_binary(player_uuid) do
    %{turn | queue: turn.queue ++ [player_uuid]}
  end

  @doc """
  Removes a player from the queue.

  ## Parameters
    * `turn` - The current turn state
    * `player_uuid` - UUID of the player to remove

  ## Examples
      iex> turn = Turn.new(queue: ["player-1", "player-2", "player-3"], cursor: 1)
      iex> Turn.remove_player_from_queue(turn, "player-2")
      %Songy.Core.Turn{queue: ["player-1", "player-3"], cursor: 0, challengers: [], track: nil}

      iex> turn = Turn.new(queue: ["player-1", "player-2", "player-3"], cursor: 0)
      iex> Turn.remove_player_from_queue(turn, "player-1")
      %Songy.Core.Turn{queue: ["player-2", "player-3"], cursor: 0, challengers: [], track: nil}
  """
  @spec remove_player_from_queue(t(), String.t()) :: t()
  def remove_player_from_queue(%__MODULE__{queue: queue} = turn, player_uuid) when is_binary(player_uuid) do
    case Enum.find_index(queue, &(&1 == player_uuid)) do
      nil ->
        turn

      player_index ->
        # Remove player from queue
        new_queue = List.delete_at(queue, player_index)

        new_index =
          cond do
            # If removed player was before current player, shift index back
            player_index < turn.cursor ->
              turn.cursor - 1

            # If removed player was current player, keep same index (now points to next player)
            player_index == turn.cursor ->
              turn.cursor

            # If removed player was after current player, no change needed
            player_index > turn.cursor ->
              turn.cursor
          end

        adjusted_index =
          if length(new_queue) > 0 do
            rem(new_index, length(new_queue))
          else
            0
          end

        %{turn | queue: new_queue, cursor: adjusted_index}
    end
  end

  @doc """
  Adds a position assumption for a player in the challenging phase.

  Uses FIFO (First In, First Out) behavior - all assumptions are preserved
  in chronological order, allowing multiple attempts from the same player.

  ## Parameters
    * `turn` - The current turn state
    * `position` - Position where player thinks track should go (0-based)
    * `player_id` - UUID of the player making the assumption

  ## Examples
      iex> turn = Turn.new()
      iex> Turn.add_assumption(turn, 2, "player-1")
      %Songy.Core.Turn{assumptions: [{2, "player-1"}]}

      iex> turn = turn |> Turn.add_assumption(1, "player-1") |> Turn.add_assumption(3, "player-1")
      iex> turn.assumptions
      [{1, "player-1"}, {3, "player-1"}]
  """
  @spec add_assumption(t(), non_neg_integer(), String.t()) :: t()
  def add_assumption(%__MODULE__{} = turn, position, player_id)
      when is_integer(position) and position >= 0 and is_binary(player_id) do
    %{turn | assumptions: turn.assumptions ++ [{position, player_id}]}
  end

  @doc """
  Sets the timeline snapshot for the challenging phase.

  ## Parameters
    * `turn` - The current turn state
    * `timeline` - List of tracks representing the active player's timeline

  ## Examples
      iex> track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      iex> track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      iex> timeline = [track1, track2]
      iex> turn = Turn.new() |> Turn.set_timeline_snapshot(timeline)
      iex> turn.timeline
      [%Track{title: "Song 1", year: 2020}, %Track{title: "Song 2", year: 2021}]
  """
  @spec set_timeline_snapshot(t(), list(Track.t())) :: t()
  def set_timeline_snapshot(%__MODULE__{} = turn, timeline) when is_list(timeline) do
    %{turn | timeline: timeline}
  end

  @doc """
  Moves to the next phase in the turn workflow.

  Automatically handles the transition logic:
  - :waiting -> :ready
  - :ready -> :steady
  - :steady -> :challenging
  - :challenging -> :results
  - :results -> :waiting (clears data and advances to next player)

  ## Parameters
    * `turn` - The current turn state

  ## Returns
    * Updated turn with next phase

  ## Examples
      iex> turn = Turn.new()
      iex> Turn.next_phase(turn)
      %Songy.Core.Turn{phase: :ready, ...}

      iex> turn = Turn.new() |> Turn.next_phase()
      iex> Turn.next_phase(turn)
      %Songy.Core.Turn{phase: :steady, ...}

      iex> # Complete cycle with player advancement
      iex> turn = Turn.new()
      iex>   |> Turn.add_player_to_queue("alice")
      iex>   |> Turn.add_player_to_queue("bob")
      iex>   |> Turn.next_phase()  # waiting -> ready
      iex>   |> Turn.next_phase()  # ready -> steady
      iex>   |> Turn.next_phase()  # steady -> challenging
      iex>   |> Turn.next_phase()  # challenging -> results
      iex>   |> Turn.next_phase()  # results -> waiting (next player)
      iex> Turn.get_active_player(turn)
      "bob"
  """
  @spec next_phase(t()) :: t()
  def next_phase(%__MODULE__{phase: :waiting} = turn) do
    %{turn | phase: :ready}
  end

  def next_phase(%__MODULE__{phase: :ready} = turn) do
    %{turn | phase: :steady}
  end

  def next_phase(%__MODULE__{phase: :steady} = turn) do
    %{turn | phase: :challenging}
  end

  def next_phase(%__MODULE__{phase: :challenging} = turn) do
    %{turn | phase: :results}
  end

  def next_phase(%__MODULE__{phase: :results, queue: queue, cursor: cursor}) do
    __MODULE__.new()
    |> Map.put(:queue, queue)
    |> Map.put(:cursor, rem(cursor + 1, max(length(queue), 1)))
  end

  @doc """
  Extends the turn's timeline by adding a track at the specified position.

  ## Parameters
    * `turn` - The turn to update
    * `track` - The track to add
    * `position` - Index position where to insert the track (0-based). Defaults to 0 (head).

  ## Examples
      iex> turn = Turn.new()
      iex> track = Track.new(title: "Song", artist: "Artist", year: 2023)

      # Add to head (default behavior)
      iex> updated_turn = Turn.extend_timeline(turn, track)
      iex> updated_turn.timeline
      [%Track{title: "Song", artist: "Artist", year: 2023}]

      # Add to specific position
      iex> track2 = Track.new(title: "Song2", artist: "Artist2", year: 2024)
      iex> updated_turn = Turn.extend_timeline(updated_turn, track2, 1)
      iex> updated_turn.timeline
      [%Track{title: "Song", artist: "Artist", year: 2023}, %Track{title: "Song2", artist: "Artist2", year: 2024}]
  """
  @spec extend_timeline(t(), Track.t(), non_neg_integer()) :: t()
  def extend_timeline(%__MODULE__{timeline: timeline} = turn, %Track{} = track, position \\ 0)
      when is_integer(position) and position >= 0 do
    %{turn | timeline: List.insert_at(timeline, position, track)}
  end

  @doc """
  Reorders a track in the turn's timeline by moving it to a new position.

  ## Parameters
    * `turn` - The turn to update
    * `track_id` - ID of the track to reorder
    * `new_position` - New position for the track (0-based)

  ## Returns
    * `{:ok, updated_turn}` - Success with updated timeline
    * `{:error, :track_not_found}` - If track not in timeline

  ## Examples
      iex> track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      iex> track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      iex> turn = Turn.new()
      iex> turn = Turn.extend_timeline(turn, track1)
      iex> turn = Turn.extend_timeline(turn, track2)
      iex> {:ok, updated_turn} = Turn.reorder_timeline(turn, track1.id, 1)
      iex> updated_turn.timeline
      [%Track{title: "Song 2"}, %Track{title: "Song 1"}]
  """
  @spec reorder_timeline(t(), String.t(), non_neg_integer()) :: {:ok, t()} | {:error, atom()}
  def reorder_timeline(%__MODULE__{timeline: timeline} = turn, track_id, new_position)
      when is_binary(track_id) and is_integer(new_position) and new_position >= 0 do
    case Enum.find(timeline, &(&1.id == track_id)) do
      nil ->
        {:error, :track_not_found}

      track ->
        {:ok,
         %{
           turn
           | timeline:
               timeline
               |> List.delete(track)
               |> List.insert_at(new_position, track)
         }}
    end
  end
end
