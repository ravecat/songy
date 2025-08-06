defmodule Songy.Core.Game do
  @moduledoc """
  Represents a multiplayer game room for the music year guessing quiz.

  A game contains participants and has a maximum capacity limit.
  Games are stored in memory during sessions and not persisted to database.
  """

  use TypedStruct

  @derive {Jason.Encoder,
           only: [:uuid, :participants, :max_participants, :status, :owner_uuid, :provider, :player, :turn, :timelines]}

  alias Songy.Core.{User, Provider, Player, Turn, Track}

  @uuid_size 6
  @type status :: :waiting | :in_progress | :finished
  @type option :: {:max_participants, pos_integer()}
  @type options :: [option()]

  typedstruct do
    field :uuid, String.t(), enforce: true
    field :participants, list(User.t()), enforce: true
    field :max_participants, pos_integer(), enforce: true
    field :created_at, DateTime.t(), enforce: true
    field :status, status(), enforce: true
    field :owner_uuid, String.t(), enforce: true
    field :provider, Provider.t(), enforce: true
    field :player, Player.t(), enforce: true
    field :turn, Turn.t()
    field :timelines, %{String.t() => list(Track.t())}, default: %{}
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
          status: :waiting,
          participants: [],
          player: Player.new(),
          timelines: %{},
          turn: Turn.new()
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
        updated_participants = [user | game.participants]
        updated_turn = Turn.add_player_to_queue(game.turn, user.uuid)
        {:ok, %{game | participants: updated_participants, turn: updated_turn}}
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
        updated_turn = Turn.remove_player_from_queue(game.turn, user_uuid)
        {:ok, %{game | participants: updated_participants, turn: updated_turn}}
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

  @doc """
  Starts playback for the game.

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> updated_game = Game.start_playback(game)
      iex> updated_game.player.is_playback
      true
  """
  @spec start_playback(t()) :: t()
  def start_playback(%__MODULE__{} = game) do
    %{game | player: Player.set_playback(game.player, true)}
  end

  @doc """
  Stops playback for the game.

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> game = Game.start_playback(game)
      iex> updated_game = Game.pause_playback(game)
      iex> updated_game.player.is_playback
      false
  """
  @spec pause_playback(t()) :: t()
  def pause_playback(%__MODULE__{} = game) do
    %{game | player: Player.set_playback(game.player, false)}
  end

  @doc """
  Toggles the playback state for the game.

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> updated_game = Game.toggle_playback(game)
      iex> updated_game.player.is_playback
      true
  """
  @spec toggle_playback(t()) :: t()
  def toggle_playback(%__MODULE__{} = game) do
    %{game | player: Player.toggle_playback(game.player)}
  end

  @doc """
  Checks if the game has no participants.

  ## Parameters
    * `game` - The game to check

  ## Returns
    * `true` - If game has no participants
    * `false` - If game has at least one participant

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> Game.empty?(game)
      true

      iex> game = Game.new("owner123", provider: provider)
      iex> user = User.get_user("user456")
      iex> {:ok, updated_game} = Game.add_participant(game, user)
      iex> Game.empty?(updated_game)
      false
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{participants: participants}) do
    Enum.empty?(participants)
  end

  @doc """
  Adds a track to a user's timeline.

  ## Parameters
    * `game` - The game to update
    * `user_uuid` - UUID of the user
    * `track` - The track to add
    * `opts` - Options for track insertion

  ## Options
    * `:position` - Index position where to insert the track (0-based). Defaults to 0 (head).

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> track = Track.new(title: "Song", artist: "Artist", year: 2023)

      # Add to head (default behavior)
      iex> updated_game = Game.add_track_to_user_timeline(game, "user456", track)
      iex> Game.get_user_timeline(updated_game, "user456")
      [%Track{title: "Song", artist: "Artist", year: 2023}]

      # Add to specific position
      iex> track2 = Track.new(title: "Song2", artist: "Artist2", year: 2024)
      iex> updated_game = Game.add_track_to_user_timeline(updated_game, "user456", track2, position: 1)
      iex> Game.get_user_timeline(updated_game, "user456")
      [%Track{title: "Song", artist: "Artist", year: 2023}, %Track{title: "Song2", artist: "Artist2", year: 2024}]
  """
  @add_track_to_timeline_options [
    position: [
      type: :non_neg_integer,
      default: 0,
      doc: "Index position where to insert the track (0-based). Defaults to 0 (head)."
    ]
  ]
  @spec add_track_to_user_timeline(t(), String.t(), Track.t(), keyword()) :: t()
  def add_track_to_user_timeline(%__MODULE__{} = game, user_uuid, %Track{} = track, opts \\ [])
      when is_binary(user_uuid) and is_list(opts) do
    opts = NimbleOptions.validate!(opts, @add_track_to_timeline_options)

    current_timeline = Map.get(game.timelines, user_uuid, [])
    position = Keyword.get(opts, :position, 0)

    updated_timeline = List.insert_at(current_timeline, position, track)

    %{game | timelines: Map.put(game.timelines, user_uuid, updated_timeline)}
  end

  @doc """
  Gets a user's timeline (list of tracks).

  ## Parameters
    * `game` - The game to query
    * `user_uuid` - UUID of the user

  ## Returns
    * List of Track structs for the user (empty list if no tracks)

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> Game.get_user_timeline(game, "user456")
      []
  """
  @spec get_user_timeline(t(), String.t()) :: list(Track.t())
  def get_user_timeline(%__MODULE__{} = game, user_uuid) when is_binary(user_uuid) do
    Map.get(game.timelines, user_uuid, [])
  end

  @doc """
  Removes a track from a user's timeline.

  ## Parameters
    * `game` - The game to update
    * `user_uuid` - UUID of the user
    * `track` - The track to remove

  ## Returns
    * Updated game with track removed from user's timeline

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> track = Track.new(title: "Song", artist: "Artist", year: 2023)
      iex> game = Game.add_track_to_user_timeline(game, "user456", track)
      iex> updated_game = Game.remove_track_from_user_timeline(game, "user456", track)
      iex> Game.get_user_timeline(updated_game, "user456")
      []
  """
  @spec remove_track_from_user_timeline(t(), String.t(), Track.t()) :: t()
  def remove_track_from_user_timeline(%__MODULE__{} = game, user_uuid, %Track{} = track)
      when is_binary(user_uuid) do
    current_timeline = Map.get(game.timelines, user_uuid, [])
    updated_timeline = List.delete(current_timeline, track)

    %{game | timelines: Map.put(game.timelines, user_uuid, updated_timeline)}
  end

  @doc """
  Checks if tracks in timeline are in chronological order (year-based).

  Returns true if each track's year is greater than or equal to the previous track's year.
  Empty timelines and single-track timelines are considered valid.

  ## Parameters
    * `timeline` - List of Track structs to validate

  ## Returns
    * `true` - If timeline is in chronological order
    * `false` - If timeline has tracks out of chronological order

  ## Examples
      iex> valid_tracks = [
      ...>   Track.new(title: "Old Song", artist: "Artist", year: 1990),
      ...>   Track.new(title: "New Song", artist: "Artist", year: 2000),
      ...>   Track.new(title: "Latest Song", artist: "Artist", year: 2020)
      ...> ]
      iex> Game.valid_timeline?(valid_tracks)
      true

      iex> invalid_tracks = [
      ...>   Track.new(title: "New Song", artist: "Artist", year: 2000),
      ...>   Track.new(title: "Old Song", artist: "Artist", year: 1990)
      ...> ]
      iex> Game.valid_timeline?(invalid_tracks)
      false

      iex> Game.valid_timeline?([])
      true
  """
  @spec valid_timeline?(list(Track.t())) :: boolean()
  def valid_timeline?([]), do: true
  def valid_timeline?([_single]), do: true

  def valid_timeline?([%Track{year: year1}, %Track{year: year2} = second | rest]) when year1 <= year2 do
    valid_timeline?([second | rest])
  end

  def valid_timeline?([%Track{}, %Track{} | _rest]), do: false

  @doc """
  Moves to the next turn in the game.

  ## Parameters
    * `game` - The game to update

  ## Returns
    * updated_game - Game with next turn
  """
  @spec next_turn(t()) :: t()
  def next_turn(%__MODULE__{turn: turn} = game) do
    %{game | turn: Turn.next_turn(turn)}
  end

  @doc """
  Sets a track for the current turn.

  ## Parameters
    * `game` - The game to update
    * `track` - The track to set

  ## Returns
    * `{:ok, updated_game}` - Success with updated game containing track in turn
    * `{:error, :no_turn}` - If game has no active turn

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> track = Track.new(title: "Song", artist: "Artist", year: 2023)
      iex> Game.set_turn_track(game, track)
      {:ok, %Game{turn: %Turn{track: %Track{title: "Song"}}}}
  """
  @spec set_turn_track(t(), Track.t()) :: {:ok, t()} | {:error, atom()}
  def set_turn_track(%__MODULE__{turn: nil} = _game, %Track{} = _track) do
    {:error, :no_turn}
  end

  def set_turn_track(%__MODULE__{turn: turn} = game, %Track{} = track) do
    {:ok, %{game | turn: Turn.set_track(turn, track)}}
  end

  @spec get_turn_track(t()) :: Track.t() | nil
  def get_turn_track(%__MODULE__{turn: nil}), do: nil

  def get_turn_track(%__MODULE__{turn: turn}) do
    Turn.get_track(turn)
  end

  @doc """
  Gets the current active player from the game queue.

  ## Parameters
    * `game` - The game to get the current player from

  ## Returns
    * UUID of the current player or nil if queue is empty or no turn
  """
  @spec get_current_player(t()) :: String.t() | nil
  def get_current_player(%__MODULE__{turn: nil}), do: nil

  def get_current_player(%__MODULE__{turn: turn}) do
    Turn.get_current_player(turn)
  end

  @spec get_status(t()) :: status()
  def get_status(%__MODULE__{status: status}), do: status

  defp user_already_joined?(%__MODULE__{participants: participants}, %User{uuid: uuid}) do
    Enum.any?(participants, &(&1.uuid == uuid))
  end

  defp generate_uuid do
    @uuid_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
