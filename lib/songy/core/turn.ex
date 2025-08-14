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

  @typep phase :: :turn_waiting | :turn_ready | :turn_steady | :turn_challenging | :turn_results

  @derive {Jason.Encoder, only: [:queue, :current_player_index, :challengers, :track, :phase]}

  typedstruct do
    field :queue, list(String.t()), default: []
    field :current_player_index, non_neg_integer(), default: 0
    field :challengers, list(String.t()), default: []
    field :track, Track.t()
    field :phase, phase(), default: :turn_waiting
  end

  @doc """
  Creates a new turn with default values.

  ## Examples
      iex> Turn.new()
      %Songy.Core.Turn{queue: [], current_player_index: 0, challengers: [], track: nil, phase: :turn_waiting}
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

  @doc """
  Gets the current phase of the turn.

  ## Parameters
    * `turn` - The current turn state

  ## Returns
    * Current phase atom

  ## Examples
      iex> turn = Turn.new()
      iex> Turn.get_phase(turn)
      :turn_waiting

      iex> turn = Turn.new() |> Turn.next_phase()
      iex> Turn.get_phase(turn)
      :turn_ready
  """
  @spec get_phase(t()) :: phase()
  def get_phase(%__MODULE__{phase: phase}), do: phase

  @doc false
  @spec clear_challengers_data(t()) :: t()
  defp clear_challengers_data(%__MODULE__{} = turn) do
    %{turn | challengers: []}
  end

  @doc false
  @spec clear_track_data(t()) :: t()
  defp clear_track_data(%__MODULE__{} = turn) do
    %{turn | track: nil}
  end

  @doc false
  @spec next_turn_player(t()) :: t()
  defp next_turn_player(%__MODULE__{queue: []} = turn), do: turn

  defp next_turn_player(%__MODULE__{queue: queue, current_player_index: index} = turn) do
    next_index = rem(index + 1, length(queue))
    %{turn | current_player_index: next_index}
  end

  @doc """
  Moves to the next phase in the turn workflow.

  Automatically handles the transition logic:
  - :turn_waiting -> :turn_ready
  - :turn_ready -> :turn_steady
  - :turn_steady -> :turn_challenging
  - :turn_challenging -> :turn_results
  - :turn_results -> :turn_waiting (clears data and advances to next player)

  ## Parameters
    * `turn` - The current turn state

  ## Returns
    * Updated turn with next phase

  ## Examples
      iex> turn = Turn.new()
      iex> Turn.next_phase(turn)
      %Songy.Core.Turn{phase: :turn_ready, ...}

      iex> turn = Turn.new() |> Turn.next_phase()
      iex> Turn.next_phase(turn)
      %Songy.Core.Turn{phase: :turn_steady, ...}

      iex> # Complete cycle with player advancement
      iex> turn = Turn.new()
      iex>   |> Turn.add_player_to_queue("alice")
      iex>   |> Turn.add_player_to_queue("bob")
      iex>   |> Turn.next_phase()  # waiting -> ready
      iex>   |> Turn.next_phase()  # ready -> steady
      iex>   |> Turn.next_phase()  # steady -> challenging
      iex>   |> Turn.next_phase()  # challenging -> results
      iex>   |> Turn.next_phase()  # results -> waiting (next player)
      iex> Turn.get_current_player(turn)
      "bob"
  """
  @spec next_phase(t()) :: t()
  def next_phase(%__MODULE__{phase: :turn_waiting} = turn) do
    %{turn | phase: :turn_ready}
  end

  def next_phase(%__MODULE__{phase: :turn_ready} = turn) do
    %{turn | phase: :turn_steady}
  end

  def next_phase(%__MODULE__{phase: :turn_steady} = turn) do
    %{turn | phase: :turn_challenging}
  end

  def next_phase(%__MODULE__{phase: :turn_challenging} = turn) do
    %{turn | phase: :turn_results}
  end

  def next_phase(%__MODULE__{phase: :turn_results} = turn) do
    %{turn | phase: :turn_waiting}
    |> clear_challengers_data()
    |> clear_track_data()
    |> next_turn_player()
  end
end
