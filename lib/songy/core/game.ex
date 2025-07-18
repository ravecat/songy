defmodule Songy.Core.Game do
  @moduledoc """
  Represents a multiplayer game room for the music year guessing quiz.

  A game contains participants and has a maximum capacity limit.
  Games are stored in memory during sessions and not persisted to database.
  """

  use TypedStruct

  @derive {Jason.Encoder, only: [:uuid, :participants, :max_participants, :status, :owner_uuid, :provider]}

  alias Songy.Core.{User, Provider}

  @uuid_size 6
  @type status :: :waiting | :in_progress | :finished
  @type option :: {:max_participants, pos_integer()}
  @type options :: [option()]

  typedstruct do
    field :uuid, String.t(), enforce: true
    field :participants, list(User.t()), default: []
    field :max_participants, pos_integer(), enforce: true
    field :created_at, DateTime.t(), enforce: true
    field :status, status(), default: :waiting
    field :owner_uuid, String.t(), enforce: true
    field :provider, Provider.t(), enforce: true
  end

  # Options for game creation based on NimbleOptions format
  @options [
    max_participants: [
      type: :pos_integer,
      doc: "Maximum number of players allowed in the game"
    ],
    provider: [
      type: {:struct, Provider},
      required: true,
      doc: "Provider instance for the game"
    ]
  ]

  @doc """
  Creates a new game with the given owner and options.

  ## Options
    * `:provider` - Provider instance (required, e.g., Provider.new(:spotify))
    * `:max_participants` - Maximum number of players allowed (default: 8)

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> Game.new("user123", provider: provider)
      %Game{uuid: "a1b2c3d4", participants: [], max_participants: 8, status: :waiting, owner_uuid: "user123", provider: %Provider{id: :spotify}}

      iex> provider = Provider.new(:spotify)
      iex> Game.new("user123", provider: provider, max_participants: 4)
      %Game{uuid: "a1b2c3d4", participants: [], max_participants: 4, status: :waiting, owner_uuid: "user123", provider: %Provider{id: :spotify}}

      iex> provider = Provider.new(:spotify)
      iex> Game.new("user123", provider: provider, max_participants: 12)
      %Game{uuid: "a1b2c3d4", participants: [], max_participants: 12, status: :waiting, owner_uuid: "user123", provider: %Provider{id: :spotify}}
  """
  @spec new(String.t(), keyword()) :: t()
  def new(owner_uuid, opts \\ []) when is_binary(owner_uuid) and is_list(opts) do
    opts = NimbleOptions.validate!(opts, @options)

    struct!(
      __MODULE__,
      Keyword.merge(
        [
          max_participants: 8,
          uuid: generate_uuid(),
          owner_uuid: owner_uuid,
          created_at: DateTime.utc_now(),
          status: :waiting
        ],
        opts
      )
    )
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
        {:ok, %{game | participants: [user | game.participants]}}
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
        {:ok, %{game | participants: updated_participants}}
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

  @doc """
  Checks if the given user UUID is the owner of the game.

  ## Parameters
    * `game` - The game to check
    * `user_uuid` - UUID of the user to check

  ## Examples
      iex> game = Game.new("owner123")
      iex> Game.owner?(game, "owner123")
      true

      iex> Game.owner?(game, "other456")
      false
  """
  @spec owner?(t(), String.t()) :: boolean()
  def owner?(%__MODULE__{owner_uuid: owner_uuid}, user_uuid) when is_binary(user_uuid) do
    owner_uuid == user_uuid
  end

  @spec update_provider(t(), Provider.t()) :: t()
  def update_provider(%__MODULE__{} = game, %Provider{} = provider) do
    %{game | provider: provider}
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
