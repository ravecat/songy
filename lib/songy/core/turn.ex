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

  @derive {Jason.Encoder, only: [:queue, :current_player_index, :challengers, :track]}

  typedstruct do
    field :queue, list(String.t()), default: []
    field :current_player_index, non_neg_integer(), default: 0
    field :challengers, list(String.t()), default: []
    field :track, Track.t()
  end

  @doc """
  Creates a new turn with default values.

  ## Examples
      iex> Turn.new()
      %Songy.Core.Turn{queue: [], current_player_index: 0, challengers: [], track: nil}
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
      %Songy.Core.Turn{queue: ["player-1"], current_player_index: 0, challengers: ["challenger-1"], track: nil}

      iex> turn = Turn.new() |> Turn.add_player_to_queue("player-1") |> Turn.add_challenger("challenger-1")
      iex> Turn.add_challenger(turn, "challenger-2")
      %Songy.Core.Turn{queue: ["player-1"], current_player_index: 0, challengers: ["challenger-1", "challenger-2"], track: nil}
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
      %Songy.Core.Turn{queue: ["player-1"], current_player_index: 0, challengers: [], track: %Track{...}}

      iex> turn = Turn.with_queue(["player-1"]) |> Turn.set_track(old_track)
      iex> Turn.set_track(turn, new_track)
      %Songy.Core.Turn{queue: ["player-1"], current_player_index: 0, challengers: [], track: %Track{...}}
  """
  @spec set_track(t(), Track.t()) :: t()
  def set_track(%__MODULE__{} = turn, %Track{} = track) do
    %{turn | track: track}
  end

  @doc """
  Gets the current player from the turn queue.

  ## Parameters
    * `turn` - The current turn state

  ## Returns
    * UUID of the current player or nil if queue is empty

  ## Examples
      iex> turn = Turn.new(queue: ["player-1", "player-2"], current_player_index: 0)
      iex> Turn.get_current_player(turn)
      "player-1"

      iex> turn = Turn.new(queue: [], current_player_index: 0)
      iex> Turn.get_current_player(turn)
      nil
  """
  @spec get_current_player(t()) :: String.t() | nil
  def get_current_player(%__MODULE__{queue: queue, current_player_index: index}) do
    Enum.at(queue, index)
  end

  @doc """
  Moves to the next turn in the game.

  ## Parameters
    * `turn` - The current turn state

  ## Returns
    * Updated turn with next player as current, or unchanged turn if queue is empty

  ## Examples
      iex> turn = Turn.new(queue: ["player-1", "player-2", "player-3"], current_player_index: 0)
      iex> Turn.next_turn(turn)
      %Songy.Core.Turn{queue: ["player-1", "player-2", "player-3"], current_player_index: 1, challengers: [], track: nil}

      iex> turn = Turn.new(queue: ["player-1"], current_player_index: 0)
      iex> Turn.next_turn(turn)
      %Songy.Core.Turn{queue: ["player-1"], current_player_index: 0, challengers: [], track: nil}

      iex> turn = Turn.new(queue: [], current_player_index: 0)
      iex> Turn.next_turn(turn)
      %Songy.Core.Turn{queue: [], current_player_index: 0, challengers: [], track: nil}
  """
  @spec next_turn(t()) :: t()
  def next_turn(%__MODULE__{queue: []} = turn), do: turn

  def next_turn(%__MODULE__{queue: queue, current_player_index: index} = turn) do
    next_index = rem(index + 1, length(queue))
    %{turn | current_player_index: next_index}
  end

  @doc """
  Adds a player to the end of the queue.

  ## Parameters
    * `turn` - The current turn state
    * `player_uuid` - UUID of the player to add

  ## Examples
      iex> turn = Turn.new(queue: ["player-1"])
      iex> Turn.add_player_to_queue(turn, "player-2")
      %Songy.Core.Turn{queue: ["player-1", "player-2"], current_player_index: 0, challengers: [], track: nil}
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
      iex> turn = Turn.new(queue: ["player-1", "player-2", "player-3"], current_player_index: 1)
      iex> Turn.remove_player_from_queue(turn, "player-2")
      %Songy.Core.Turn{queue: ["player-1", "player-3"], current_player_index: 0, challengers: [], track: nil}

      iex> turn = Turn.new(queue: ["player-1", "player-2", "player-3"], current_player_index: 0)
      iex> Turn.remove_player_from_queue(turn, "player-1")
      %Songy.Core.Turn{queue: ["player-2", "player-3"], current_player_index: 0, challengers: [], track: nil}
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
            player_index < turn.current_player_index ->
              turn.current_player_index - 1

            # If removed player was current player, keep same index (now points to next player)
            player_index == turn.current_player_index ->
              turn.current_player_index

            # If removed player was after current player, no change needed
            player_index > turn.current_player_index ->
              turn.current_player_index
          end

        adjusted_index =
          if length(new_queue) > 0 do
            rem(new_index, length(new_queue))
          else
            0
          end

        %{turn | queue: new_queue, current_player_index: adjusted_index}
    end
  end
end
