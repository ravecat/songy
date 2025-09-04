defmodule Songy.Core.Game do
  @moduledoc """
  Represents a multiplayer game room for the music year guessing quiz.

  A game contains participants and has a maximum capacity limit.
  Games are stored in memory during sessions and not persisted to database.
  """

  use TypedStruct

  @derive {Jason.Encoder,
           only: [
             :uuid,
             :participants,
             :max_participants,
             :status,
             :owner_uuid,
             :provider,
             :player,
             :turn,
             :timelines,
             :scores
           ]}

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
    field :scores, %{String.t() => integer()}, default: %{}
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
          scores: %{},
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
        {:ok,
         %{
           game
           | participants: [user | game.participants],
             turn: Turn.add_player_to_queue(game.turn, user.uuid),
             scores: Map.put_new(game.scores, user.uuid, 0)
         }}
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
  def remove_participant(%__MODULE__{participants: participants} = game, user_uuid)
      when is_binary(user_uuid) do
    case Enum.reject(participants, &(&1.uuid == user_uuid)) do
      ^participants ->
        {:error, :user_not_found}

      updated_participants ->
        {:ok,
         %{
           game
           | participants: updated_participants,
             turn: Turn.remove_player_from_queue(game.turn, user_uuid)
         }}
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
  use extend_user_timeline/2 instead.

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
  Extends a user's timeline by adding the current turn track at the chronologically correct position.

  This function automatically places the track in chronological order based on the track's year.
  The track is automatically retrieved from the current turn and placed at the appropriate position
  to maintain chronological ordering by year.

  For initializing new user timelines, use init_user_timeline/3 instead.

  ## Parameters
    * `game` - The game to update
    * `user_uuid` - UUID of the user

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> track1 = Track.new(title: "Old Song", artist: "Artist", year: 2020)
      iex> track2 = Track.new(title: "New Song", artist: "Artist", year: 2023)

      # Add first track
      iex> {:ok, game_with_track1} = Game.set_turn_track(game, track1)
      iex> game = Game.extend_user_timeline(game_with_track1, "user456")
      iex> Game.get_user_timeline(game, "user456")
      [%Track{title: "Old Song", year: 2020}]

      # Add newer track - automatically positioned after older track
      iex> {:ok, game_with_track2} = Game.set_turn_track(game, track2)
      iex> updated_game = Game.extend_user_timeline(game_with_track2, "user456")
      iex> Game.get_user_timeline(updated_game, "user456")
      [%Track{title: "Old Song", year: 2020}, %Track{title: "New Song", year: 2023}]
  """
  @spec extend_user_timeline(t(), String.t()) :: t()
  def extend_user_timeline(%__MODULE__{} = game, user_uuid) when is_binary(user_uuid) do
    track = get_turn_track(game)
    current_timeline = get_user_timeline(game, user_uuid)

    position =
      Enum.find_index(current_timeline, &(&1.year > track.year)) || length(current_timeline)

    updated_timeline = List.insert_at(current_timeline, position, track)

    %{game | timelines: Map.put(game.timelines, user_uuid, updated_timeline)}
  end

  @doc """
  Adds the current turn track to the active timeline at the specified position and records user assumption.

  Retrieves the track from the current turn and inserts it into the turn timeline
  at the given position. Also records the user's assumption about track position.
  This represents adding the current playing track to the active game timeline
  during the challenging phase while tracking which user made the assumption.

  If the user making the assumption is the active player, automatically advances
  the game to the next phase.

  ## Parameters
    * `game` - The current game state
    * `user_uuid` - UUID of the user making the assumption
    * `position` - Position to insert the track (0-based index). Defaults to 0 (head).

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> track = Track.new(title: "Song", artist: "Artist", year: 2023)
      iex> game_with_track = Game.set_turn_track(game, track)

      # Non-active player makes assumption - no phase change
      iex> updated_game = Game.extend_active_timeline(game_with_track, "user456")
      iex> updated_game.turn.timeline
      [%Track{title: "Song", artist: "Artist", year: 2023}]
      iex> updated_game.turn.assumptions
      [%{position: 0, user_id: "user456"}]
      iex> updated_game.turn.phase
      :steady  # Phase unchanged

      # Active player makes assumption - phase advances automatically
      iex> active_player_uuid = Turn.get_active_player(game.turn)
      iex> updated_game = Game.extend_active_timeline(game_with_track, active_player_uuid)
      iex> updated_game.turn.phase
      :challenging  # Phase advanced automatically
  """
  @spec extend_active_timeline(t(), String.t(), non_neg_integer()) :: t()
  def extend_active_timeline(%__MODULE__{turn: turn} = game, user_uuid, position \\ 0)
      when is_binary(user_uuid) and is_integer(position) and position >= 0 do
    track = get_turn_track(game)
    active_player_uuid = Turn.get_active_player(turn)
    game = %{game | turn: Turn.update_timeline(turn, track, user_uuid, position)}

    if user_uuid == active_player_uuid do
      next_phase(game)
    else
      game
    end
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
  Reorders a track in the active timeline by moving it to a new position.
  Uses the user's assumption to find and move their track.

  ## Parameters
    * `game` - The game to update
    * `user_uuid` - UUID of the user whose track to reorder
    * `new_position` - New position for the track (0-based)

  ## Returns
    * `{:ok, updated_game}` - Success with updated timeline and synchronized assumptions
    * `{:error, :user_assumption_not_found}` - If user has no assumption in timeline
    * `{:error, :no_turn}` - If game has no active turn

  ## Examples
      iex> {:ok, updated_game} = Game.reorder_active_timeline(game, "user1", 0)
  """
  @spec reorder_active_timeline(t(), String.t(), non_neg_integer()) :: {:ok, t()} | {:error, atom()}
  def reorder_active_timeline(%__MODULE__{turn: nil} = _game, _user_uuid, _new_position) do
    {:error, :no_turn}
  end

  def reorder_active_timeline(%__MODULE__{turn: turn} = game, user_uuid, new_position)
      when is_binary(user_uuid) and is_integer(new_position) and new_position >= 0 do
    case Turn.reorder_timeline(turn, user_uuid, new_position) do
      {:ok, updated_turn} ->
        {:ok, %{game | turn: updated_turn}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp valid_assumption?(timeline, position) do
    case Enum.at(timeline, position) do
      nil ->
        false

      %Track{year: year} ->
        left_neighbor = if position > 0, do: Enum.at(timeline, position - 1), else: nil
        right_neighbor = Enum.at(timeline, position + 1)

        left_valid = is_nil(left_neighbor) or left_neighbor.year <= year
        right_valid = is_nil(right_neighbor) or year <= right_neighbor.year

        left_valid and right_valid
    end
  end

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
    active_player_uuid = Turn.get_active_player(new_turn)
    active_player_timeline = get_user_timeline(game, active_player_uuid)
    updated_turn = Turn.snapshot_user_timeline(new_turn, active_player_timeline)

    %{game | turn: updated_turn}
  end

  def next_phase(
        %__MODULE__{turn: %Turn{phase: :challenging, assumptions: assumptions, timeline: timeline} = turn} = game
      ) do
    updated_game =
      case Enum.find(assumptions, &valid_assumption?(timeline, &1.position)) do
        %{user_id: user_uuid} ->
          game
          |> increment_user_score(user_uuid)
          |> extend_user_timeline(user_uuid)

        nil ->
          game
      end

    %{updated_game | turn: Turn.next_phase(turn)}
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

  @doc """
  Adds points to a player's score. Defaults to 1 point if not specified.

  If player key doesn't exist in scores, returns the game unchanged.

  ## Parameters
    * `game` - The game to update
    * `user_uuid` - UUID of the player
    * `points` - Points to add (defaults to 1)

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> user = User.new()
      iex> {:ok, game_with_user} = Game.add_participant(game, user)
      iex> updated_game = Game.increment_user_score(game_with_user, user.uuid)
      iex> Game.get_player_score(updated_game, user.uuid)
      1
  """
  @spec increment_user_score(t(), String.t(), integer()) :: t()
  def increment_user_score(%__MODULE__{} = game, user_uuid, points \\ 1)
      when is_binary(user_uuid) and is_integer(points) do
    case Map.get(game.scores, user_uuid) do
      nil ->
        game

      current_score ->
        new_score = current_score + points
        %{game | scores: Map.put(game.scores, user_uuid, new_score)}
    end
  end

  @doc """
  Gets the current score for a specific player.

  ## Parameters
    * `game` - The game to query
    * `user_uuid` - UUID of the player

  ## Returns
    * Score as integer, or 0 if player not found

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> user = User.new()
      iex> {:ok, game_with_user} = Game.add_participant(game, user)
      iex> Game.get_player_score(game_with_user, user.uuid)
      0
  """
  @spec get_player_score(t(), String.t()) :: integer()
  def get_player_score(%__MODULE__{} = game, user_uuid) when is_binary(user_uuid) do
    Map.get(game.scores, user_uuid, 0)
  end

  @doc """
  Gets all player scores as a map.

  ## Parameters
    * `game` - The game to query

  ## Returns
    * Map with user UUIDs as keys and scores as values

  ## Examples
      iex> provider = Provider.new(:spotify)
      iex> game = Game.new("owner123", provider: provider)
      iex> user1 = User.new()
      iex> user2 = User.new()
      iex> {:ok, game} = Game.add_participant(game, user1)
      iex> {:ok, game} = Game.add_participant(game, user2)
      iex> game = Game.increment_user_score(game, user1.uuid, 100)
      iex> game = Game.increment_user_score(game, user2.uuid, 75)
      iex> scores = Game.get_all_scores(game)
      iex> Map.get(scores, user1.uuid)
      100
  """
  @spec get_all_scores(t()) :: %{String.t() => integer()}
  def get_all_scores(%__MODULE__{scores: scores}), do: scores

  defp user_already_joined?(%__MODULE__{participants: participants}, %User{uuid: uuid}) do
    Enum.any?(participants, &(&1.uuid == uuid))
  end

  defp generate_uuid do
    @uuid_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
