defmodule Songy.Core.Turn do
  @moduledoc """
  Represents an active turn in the music year guessing quiz.

  A turn contains information about the current game state:
  - which player is active (determined by queue position)
  - what track is currently being played
  - the queue of players and current player index
  """

  use TypedStruct

  alias Songy.Core.Track

  @typep phase :: :waiting | :ready | :steady | :challenging | :results

  @derive {Jason.Encoder, only: [:queue, :cursor, :track, :phase, :timeline, :assumptions]}

  typedstruct do
    field :queue, list(String.t()), default: []
    field :cursor, non_neg_integer(), default: 0
    field :track, Track.t()
    field :phase, phase(), default: :waiting
    field :timeline, list(Track.t()), default: []
    field :assumptions, list(%{position: non_neg_integer(), user_id: String.t()}), default: []
  end

  @doc """
  Creates a new turn with default values.

  ## Examples
      iex> Turn.new()
      %Songy.Core.Turn{queue: [], cursor: 0, track: nil, phase: :waiting}
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Sets the track for the turn.

  ## Parameters
    * `turn` - The current turn state
    * `track` - The track to set

  ## Examples
      iex> turn = Turn.with_queue(["player-1"])
      iex> track = Track.new(title: "Song", artist: "Artist", year: 2020)
      iex> Turn.set_track(turn, track)
      %Songy.Core.Turn{queue: ["player-1"], cursor: 0, track: %Track{...}}

      iex> turn = Turn.with_queue(["player-1"]) |> Turn.set_track(old_track)
      iex> Turn.set_track(turn, new_track)
      %Songy.Core.Turn{queue: ["player-1"], cursor: 0, track: %Track{...}}
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
      %Songy.Core.Turn{queue: ["player-1", "player-2"], cursor: 0, track: nil}
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
      %Songy.Core.Turn{queue: ["player-1", "player-3"], cursor: 0, track: nil}

      iex> turn = Turn.new(queue: ["player-1", "player-2", "player-3"], cursor: 0)
      iex> Turn.remove_player_from_queue(turn, "player-1")
      %Songy.Core.Turn{queue: ["player-2", "player-3"], cursor: 0, track: nil}
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
  Creates a snapshot of the user's timeline for the challenging phase.

  ## Parameters
    * `turn` - The current turn state
    * `timeline` - List of tracks representing the active player's timeline

  ## Examples
      iex> track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      iex> track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      iex> timeline = [track1, track2]
      iex> turn = Turn.new() |> Turn.snapshot_user_timeline(timeline)
      iex> turn.timeline
      [%Track{title: "Song 1", year: 2020}, %Track{title: "Song 2", year: 2021}]
  """
  @spec snapshot_user_timeline(t(), list(Track.t())) :: t()
  def snapshot_user_timeline(%__MODULE__{} = turn, timeline) when is_list(timeline) do
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
  Adds a track to the timeline at the specified position and synchronizes assumption positions.

  This function handles both timeline modification and assumption synchronization
  in a single atomic operation. Always adds the track without checking for existing duplicates.
  Used for player assumptions in challenging phase where multiple
  players can place the same track at different positions.

  Removes any existing assumptions from the same user before adding the new one,
  as each player can only have one active assumption at a time.

  Automatically updates all remaining assumptions to account for position shifts
  caused by the insertion - assumptions at or after the insertion position
  are incremented by 1.

  ## Parameters
    * `turn` - The turn to update
    * `track` - The track to add
    * `user_uuid` - UUID of the user making this assumption
    * `position` - Index position where to place the track (0-based). Defaults to 0 (head).

  ## Examples
      # Adding tracks at different positions (duplicates allowed)
      iex> turn = Turn.new()
      iex> track = Track.new(title: "Song", artist: "Artist", year: 2023)
      iex> turn = Turn.update_timeline(turn, track, "user1", 0)
      iex> turn = Turn.update_timeline(turn, track, "user2", 2)  # Same track, different position
      iex> length(turn.timeline)
      2

      # User's new assumption replaces their previous one
      iex> turn = Turn.new()
      iex> track1 = Track.new(title: "Song1", artist: "Artist1", year: 2023)
      iex> turn = Turn.update_timeline(turn, track1, "user1", 1)
      iex> track2 = Track.new(title: "Song2", artist: "Artist2", year: 2024)
      iex> updated_turn = Turn.update_timeline(turn, track2, "user1", 0)
      iex> # user1's old assumption is removed, only new assumption at position 0 remains
      iex> updated_turn.assumptions
      [%{position: 0, user_id: "user1"}]
  """
  @spec update_timeline(t(), Track.t(), String.t(), non_neg_integer()) :: t()
  def update_timeline(
        %__MODULE__{timeline: timeline, assumptions: assumptions} = turn,
        %Track{} = track,
        user_uuid,
        position \\ 0
      )
      when is_binary(user_uuid) and is_integer(position) and position >= 0 do
    effective_position = min(position, length(timeline))

    timeline = List.insert_at(timeline, effective_position, track)

    assumptions =
      Enum.reject(assumptions, &(&1.user_id == user_uuid))
      |> Enum.map(fn %{position: pos} = assumption ->
        new_pos = if pos >= effective_position, do: pos + 1, else: pos

        %{assumption | position: new_pos}
      end)
      |> then(&(&1 ++ [%{position: effective_position, user_id: user_uuid}]))

    %{turn | timeline: timeline, assumptions: assumptions}
  end

  @doc """
  Reorders a track in the turn's timeline by moving it to a new position.
  Uses the user's assumption to find the current track position and moves it to the new position.

  This function finds the track through the user's assumption, removes the old assumption,
  moves the track in the timeline, and updates all assumption positions using the same
  simple logic as update_timeline.

  ## Parameters
    * `turn` - The turn to update
    * `user_uuid` - UUID of the user whose track to reorder
    * `new_position` - New position for the track (0-based)

  ## Returns
    * `{:ok, updated_turn}` - Success with updated timeline and synchronized assumptions
    * `{:error, :user_assumption_not_found}` - If user has no assumption in timeline

  ## Examples
      iex> track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      iex> track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      iex> turn = Turn.new()
      iex> turn = Turn.update_timeline(turn, track1, "player-1", 0)
      iex> turn = Turn.update_timeline(turn, track2, "player-2", 0)
      iex> {:ok, updated_turn} = Turn.reorder_timeline(turn, "player-1", 1)
      iex> updated_turn.timeline
      [%Track{title: "Song 2"}, %Track{title: "Song 1"}]
      iex> updated_turn.assumptions
      [%{position: 0, user_id: "player-2"}, %{position: 1, user_id: "player-1"}]
  """
  @spec reorder_timeline(t(), String.t(), non_neg_integer()) :: {:ok, t()} | {:error, atom()}
  def reorder_timeline(%__MODULE__{timeline: timeline, assumptions: assumptions} = turn, user_uuid, new_position)
      when is_binary(user_uuid) and is_integer(new_position) and new_position >= 0 do
    case Enum.find(assumptions, &(&1.user_id == user_uuid)) do
      nil ->
        {:error, :user_assumption_not_found}

      %{position: prev_pos} ->
        track = Enum.at(timeline, prev_pos)

        timeline =
          timeline
          |> List.delete_at(prev_pos)
          |> List.insert_at(new_position, track)

        assumptions =
          Enum.reject(assumptions, &(&1.user_id == user_uuid))
          |> Enum.map(fn %{position: pos} = assumption ->
            new_pos =
              cond do
                # Track moved right: positions between old and new shift left
                prev_pos < new_position and pos > prev_pos and pos <= new_position ->
                  pos - 1

                # Track moved left: positions between new and old shift right
                prev_pos > new_position and pos >= new_position and pos < prev_pos ->
                  pos + 1

                true ->
                  pos
              end

            %{assumption | position: new_pos}
          end)
          |> then(&(&1 ++ [%{position: new_position, user_id: user_uuid}]))

        {:ok, %{turn | timeline: timeline, assumptions: assumptions}}
    end
  end
end
