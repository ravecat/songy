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
  Moves the game to the next status automatically.

  Automatically transitions through the game states:
  - :waiting -> :in_progress
  - :in_progress -> :finished
  - :finished -> error (game cannot be advanced further)

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> Game.update_status(game)
      {:ok, %Game{status: :in_progress}}

      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> {:ok, in_progress_game} = Game.update_status(game)
      iex> Game.update_status(in_progress_game)
      {:ok, %Game{status: :finished}}

      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> {:ok, in_progress_game} = Game.update_status(game)
      iex> {:ok, finished_game} = Game.update_status(in_progress_game)
      iex> Game.update_status(finished_game)
      {:error, :game_already_finished}
  """
  @spec update_status(t()) :: {:ok, t()} | {:error, atom()}
  def update_status(%__MODULE__{status: :waiting} = game) do
    {:ok, %{game | status: :in_progress}}
  end

  def update_status(%__MODULE__{status: :in_progress} = game) do
    {:ok, %{game | status: :finished}}
  end

  def update_status(%__MODULE__{status: :finished}) do
    {:error, :game_already_finished}
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
  Initializes a user's timeline with a single track.

  This function is specifically for creating initial timelines when users join a game.
  The track is always placed at position 0. For general timeline management during gameplay,
  use extend_user_timeline/4 instead.

  ## Parameters
    * `game` - The game to update
    * `user_uuid` - UUID of the user
    * `track` - The initial track to add

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> track = Track.new(title: "Initial Song", artist: "Artist", year: 2023)
      iex> updated_game = Game.init_user_timeline(game, "user456", track)
      iex> Game.get_user_timeline(updated_game, "user456")
      [%Track{title: "Initial Song", artist: "Artist", year: 2023}]
  """
  @spec init_user_timeline(t(), String.t(), Track.t()) :: t()
  def init_user_timeline(%__MODULE__{} = game, user_uuid, %Track{} = track)
      when is_binary(user_uuid) do
    %{game | timelines: Map.put(game.timelines, user_uuid, [track])}
  end

  @doc """
  Extends a user's timeline by adding the current turn track at the specified position.

  This function is used for managing user timelines during gameplay.
  The track is automatically retrieved from the current turn.
  For initializing new user timelines, use init_user_timeline/3 instead.

  ## Parameters
    * `game` - The game to update
    * `user_uuid` - UUID of the user
    * `position` - Index position where to insert the track (0-based). Defaults to 0 (head).

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> track = Track.new(title: "Song", artist: "Artist", year: 2023)
      iex> game_with_track = Game.set_turn_track(game, track)

      # Add to head (default behavior)
      iex> updated_game = Game.extend_user_timeline(game_with_track, "user456")
      iex> Game.get_user_timeline(updated_game, "user456")
      [%Track{title: "Song", artist: "Artist", year: 2023}]

      # Add to specific position
      iex> track2 = Track.new(title: "Song2", artist: "Artist2", year: 2024)
      iex> game_with_track2 = Game.set_turn_track(game_with_track, track2)
      iex> updated_game = Game.extend_user_timeline(game_with_track2, "user456", 1)
      iex> Game.get_user_timeline(updated_game, "user456")
      [%Track{title: "Song", artist: "Artist", year: 2023}, %Track{title: "Song2", artist: "Artist2", year: 2024}]
  """
  @spec extend_user_timeline(t(), String.t(), non_neg_integer()) :: t()
  def extend_user_timeline(%__MODULE__{} = game, user_uuid, position \\ 0)
      when is_binary(user_uuid) and is_integer(position) and position >= 0 do
    track = get_turn_track(game)
    current_timeline = Map.get(game.timelines, user_uuid, [])
    updated_timeline = List.insert_at(current_timeline, position, track)

    %{game | timelines: Map.put(game.timelines, user_uuid, updated_timeline)}
  end

  @doc """
  Extends the active player's timeline by adding a track at the specified position during the current turn.

  This function works with the turn's timeline snapshot, not the user's persistent timeline.
  It modifies the timeline stored in the current turn structure.

  ## Parameters
    * `game` - The game to update
    * `track` - The track to add
    * `position` - Index position where to insert the track (0-based). Defaults to 0 (head).

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> track = Track.new(title: "Song", artist: "Artist", year: 2023)

      # Add to head (default behavior)
      iex> updated_game = Game.extend_active_timeline(game, track)
      iex> updated_game.turn.timeline
      [%Track{title: "Song", artist: "Artist", year: 2023}]

      # Add to specific position
      iex> track2 = Track.new(title: "Song2", artist: "Artist2", year: 2024)
      iex> updated_game = Game.extend_active_timeline(updated_game, track2, 1)
      iex> updated_game.turn.timeline
      [%Track{title: "Song", artist: "Artist", year: 2023}, %Track{title: "Song2", artist: "Artist2", year: 2024}]
  """
  @spec extend_active_timeline(t(), Track.t(), non_neg_integer()) :: t()
  def extend_active_timeline(%__MODULE__{turn: turn} = game, %Track{} = track, position \\ 0)
      when is_integer(position) and position >= 0 do
    %{game | turn: Turn.extend_timeline(turn, track, position)}
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
  Reorders a track in user's timeline by moving it to a new position.

  ## Parameters
    * `game` - The game to update
    * `user_uuid` - UUID of the user
    * `track_id` - ID of the track to reorder
    * `new_position` - New position for the track (0-based)

  ## Returns
    * `{:ok, updated_game}` - Success with updated timeline
    * `{:error, :track_not_found}` - If track not in timeline

  ## Examples
      iex> track1 = Track.new(title: "Song 1", artist: "Artist", year: 2020)
      iex> track2 = Track.new(title: "Song 2", artist: "Artist", year: 2021)
      iex> track3 = Track.new(title: "Song 3", artist: "Artist", year: 2022)

      # Build timeline: [track3, track2, track1]
      iex> game = game
      ...> |> Game.extend_user_timeline("user456", track1)
      ...> |> Game.extend_user_timeline("user456", track2)
      ...> |> Game.extend_user_timeline("user456", track3)

      # Move track1 to position 0: [track1, track3, track2]
      iex> {:ok, updated_game} = Game.reorder_user_timeline(game, "user456", track1.id, 0)
  """
  @spec reorder_user_timeline(t(), String.t(), String.t(), non_neg_integer()) :: {:ok, t()} | {:error, atom()}
  def reorder_user_timeline(%__MODULE__{} = game, user_uuid, track_id, new_position)
      when is_binary(user_uuid) and is_binary(track_id) and is_integer(new_position) and new_position >= 0 do
    timeline = get_user_timeline(game, user_uuid)

    case Enum.find(timeline, &(&1.id == track_id)) do
      nil ->
        {:error, :track_not_found}

      track ->
        # Remove track from current position, then add at new position
        updated_timeline = List.delete(timeline, track)
        final_timeline = List.insert_at(updated_timeline, new_position, track)

        updated_game = %{game | timelines: Map.put(game.timelines, user_uuid, final_timeline)}
        {:ok, updated_game}
    end
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
  Moves to the next phase in the game.

  ## Parameters
    * `game` - The game to update

  ## Returns
    * updated_game - Game with next phase
  """
  @spec next_phase(t()) :: t()
  def next_phase(%__MODULE__{turn: %Turn{phase: :waiting} = turn} = game) do
    # Create snapshot of active player's timeline when starting their turn
    new_turn = Turn.next_phase(turn)
    new_active_player_uuid = Turn.get_active_player(new_turn)
    new_active_player_timeline = get_user_timeline(game, new_active_player_uuid)
    updated_turn = Turn.set_timeline_snapshot(new_turn, new_active_player_timeline)
    %{game | turn: updated_turn}
  end

  def next_phase(%__MODULE__{turn: turn} = game) do
    %{game | turn: Turn.next_phase(turn)}
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

  @spec get_turn_track(t()) :: Track.t()
  def get_turn_track(%__MODULE__{turn: turn}) do
    Turn.get_track(turn)
  end

  @doc """
  Gets the current active player from the game queue.

  ## Parameters
    * `game` - The game to get the active player from

  ## Returns
    * UUID of the active player or nil if queue is empty or no turn
  """
  @spec get_active_player(t()) :: String.t() | nil
  def get_active_player(%__MODULE__{turn: nil}), do: nil

  def get_active_player(%__MODULE__{turn: turn}) do
    Turn.get_active_player(turn)
  end

  @spec get_status(t()) :: status()
  def get_status(%__MODULE__{status: status}), do: status

  @doc """
  Gets the provider for the game.

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("user123", provider: provider)
      iex> Game.get_provider(game)
      %Provider{id: :spotify}
  """
  @spec get_provider(t()) :: Provider.t()
  def get_provider(%__MODULE__{provider: provider}), do: provider

  defp user_already_joined?(%__MODULE__{participants: participants}, %User{uuid: uuid}) do
    Enum.any?(participants, &(&1.uuid == uuid))
  end

  defp generate_uuid do
    @uuid_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
