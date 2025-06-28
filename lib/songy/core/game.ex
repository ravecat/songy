defmodule Songy.Core.Game do
  @moduledoc """
  Represents a multiplayer game room for the music year guessing quiz.

  A game contains participants and has a maximum capacity limit.
  Games are stored in memory during sessions and not persisted to database.
  """

  use TypedStruct

  @derive {Jason.Encoder, only: [:uuid, :participants, :max_participants, :status]}

  alias Songy.Core.User

  @uuid_size 6
  @type status :: :waiting | :in_progress | :finished

  typedstruct do
    field :uuid, String.t(), enforce: true
    field :participants, list(User.t()), default: []
    field :max_participants, pos_integer(), default: 6
    field :created_at, DateTime.t(), enforce: true
    field :status, status(), default: :waiting
  end

  @doc """
  Creates a new game with given maximum participants.

  ## Parameters
    * `max_participants` - Maximum number of players allowed (default: 6)

  ## Examples
      iex> Game.new()
      %Game{uuid: "a1b2c3d4", participants: [], max_participants: 6}

      iex> Game.new(4)
      %Game{uuid: "a1b2c3d4", participants: [], max_participants: 4}
  """
  @spec new(pos_integer()) :: t()
  def new(max_participants \\ 6) when is_integer(max_participants) and max_participants > 0 do
    %__MODULE__{
      uuid: generate_uuid(),
      max_participants: max_participants,
      created_at: DateTime.utc_now()
    }
  end

  @doc """
  Creates a new game with a specified UUID.

  ## Parameters
    * `uuid` - UUID to use for the game (typically room_id)
    * `max_participants` - Maximum number of participants allowed

  ## Examples
      iex> Game.new_with_uuid("room123", 4)
      %Game{uuid: "room123", participants: [], max_participants: 4}
  """
  @spec new_with_uuid(String.t(), pos_integer()) :: t()
  def new_with_uuid(uuid, max_participants \\ 6)
      when is_binary(uuid) and is_integer(max_participants) and max_participants > 0 do
    %__MODULE__{
      uuid: uuid,
      max_participants: max_participants,
      created_at: DateTime.utc_now()
    }
  end

  @doc """
  Adds a user to the game if there's available space.

  ## Parameters
    * `game` - The game to add user to
    * `user` - The user to add

  ## Returns
    * `{:ok, updated_game}` - If user was successfully added
    * `{:error, :game_full}` - If game has reached maximum capacity
    * `{:error, :user_already_joined}` - If user is already in the game
  """
  @spec add_participant(t(), User.t()) :: {:ok, t()} | {:error, atom()}
  def add_participant(%__MODULE__{} = game, %User{} = user) do
    cond do
      length(game.participants) >= game.max_participants ->
        {:error, :game_full}

      user_already_joined?(game, user) ->
        {:error, :user_already_joined}

      true ->
        updated_game = %{game | participants: [user | game.participants]}
        {:ok, updated_game}
    end
  end

  @doc """
  Removes a user from the game.

  ## Parameters
    * `game` - The game to remove user from
    * `user_uuid` - UUID of the user to remove

  ## Returns
    * `{:ok, updated_game}` - If user was successfully removed
    * `{:error, :user_not_found}` - If user is not in the game
  """
  @spec remove_participant(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def remove_participant(%__MODULE__{} = game, user_uuid) when is_binary(user_uuid) do
    original_participants = game.participants
    updated_participants = Enum.reject(game.participants, &(&1.uuid == user_uuid))

    case updated_participants do
      ^original_participants ->
        {:error, :user_not_found}

      _ ->
        updated_game = %{game | participants: updated_participants}
        {:ok, updated_game}
    end
  end

  @doc """
  Gets the current number of participants in the game.
  """
  @spec participant_count(t()) :: non_neg_integer()
  def participant_count(%__MODULE__{participants: participants}) do
    length(participants)
  end

  @doc """
  Checks if the game is full.
  """
  @spec full?(t()) :: boolean()
  def full?(%__MODULE__{} = game) do
    participant_count(game) >= game.max_participants
  end

  @doc """
  Updates the game status.
  """
  @spec update_status(t(), status()) :: t()
  def update_status(%__MODULE__{} = game, status)
      when status in [:waiting, :in_progress, :finished] do
    %{game | status: status}
  end

  defp user_already_joined?(%__MODULE__{participants: participants}, %User{uuid: uuid}) do
    Enum.any?(participants, &(&1.uuid == uuid))
  end

  defp generate_uuid do
    @uuid_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
