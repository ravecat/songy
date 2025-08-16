defmodule Songy.Boundary.GameSession do
  @moduledoc """
  GenServer for managing game session state and player interactions.

  Each game session is a separate process that maintains the state of
  an active game room. Sessions are dynamically created and supervised
  by the GameSession supervisor.

  ## Public API

    * `create_game_session/2` - Creates and starts a new game session process with owner and provider
    * `remove_participant/2` - Removes a participant from an existing game session
    * `lookup_game_session/1` - Retrieves the current state of a game session
    * `start_game_session/1` - Starts the game by changing its status to in_progress
    * `start_playback/2` - Starts playback for the game session
    * `pause_playback/2` - Pauses playback for the game session
    * `end_game_session/1` - Terminates a game session process
    * `owner?/2` - Checks if a user is the owner of a game session
    * `update_provider/2` - Updates the provider for a game session (owner only)
    * `set_credentials/2` - Stores provider credentials in Registry for session access
    * `get_credentials/1` - Retrieves stored credentials from Registry
    * `extend_timeline/2` - Adds current turn track to user's timeline at beginning (position 0)
    * `extend_timeline/3` - Adds current turn track to user's timeline at specified position
    * `reorder_timeline/4` - Reorders a track in user's timeline to new position

  ## Process Management

  Game sessions are registered in `Songy.Registry` using their UUID as the key.
  This allows for efficient lookup and ensures uniqueness across all sessions.

  Sessions are supervised by `Songy.Supervisor.GameSession` and will be
  automatically restarted if they crash unexpectedly.
  """

  use GenServer

  alias Songy.Core.{Game, User, Provider, Trackable, Track}
  alias Songy.Core.Provider.Credentials
  alias Songy.Boundary.Spotify

  require Logger

  @doc """
  Creates and starts a new game session process with specified owner and provider.

  Generates a new game with a random UUID and starts the session process.

  ## Parameters
    * `owner_uuid` - UUID of the user who will own the game room
    * `provider_id` - Provider identifier atom (e.g., :spotify)

  ## Examples
      iex> GameSession.create_game_session("user123", :spotify)
      {:ok, %Game{uuid: "a1b2c3", participants: [], owner_uuid: "user123", provider: %Provider{id: :spotify}}}

      iex> GameSession.create_game_session("invalid", :spotify)
      {:error, :process_start_failed}
  """
  @spec create_game_session(String.t(), atom()) :: {:ok, Game.t()} | {:error, term()}
  def create_game_session(owner_uuid, provider_id) when is_binary(owner_uuid) and is_atom(provider_id) do
    with provider <- Provider.new(provider_id),
         game <- Game.new(owner_uuid, provider: provider),
         {:ok, _pid} <-
           DynamicSupervisor.start_child(
             Songy.Supervisor.GameSession,
             {__MODULE__, game}
           ) do
      {:ok, game}
    else
      {:error, {:already_started, _pid}} -> {:error, :already_exists}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Terminates a game session.

  ## Parameters
    * `game_uuid` - UUID of the game session to terminate
  """
  @spec end_game_session(String.t()) :: :ok
  def end_game_session(game_uuid, reason \\ :normal, timeout \\ :infinity) do
    if game_session_exists?(game_uuid) do
      GenServer.stop(via(game_uuid), reason, timeout)
    else
      :ok
    end
  end

  @doc """
  Removes a participant from the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `participant_uuid` - UUID of the participant to remove

  ## Examples
      iex> GameSession.remove_participant("game123", "user456")
      {:ok, %Game{participants: []}}

      iex> GameSession.remove_participant("game123", "nonexistent_user")
      {:error, :user_not_found}
  """
  @spec remove_participant(String.t(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def remove_participant(game_uuid, participant_uuid) do
    if game_session_exists?(game_uuid) do
      GenServer.call(via(game_uuid), {:remove_participant, participant_uuid})
    else
      {:error, :game_session_not_found}
    end
  end

  @doc """
  Starts the game by changing its status to in_progress.

  ## Parameters
    * `game_uuid` - UUID of the game session

  ## Examples
      iex> GameSession.start_game_session("game123")
      {:ok, %Game{status: :in_progress}}

      iex> GameSession.start_game_session("nonexistent")
      {:error, :game_session_not_found}
  """
  @spec start_game_session(String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def start_game_session(game_uuid) do
    with {:ok, game} <- lookup_game_session(game_uuid),
         :waiting <- Game.get_status(game),
         {:ok, credentials} <- get_credentials(game_uuid),
         {:ok, random_track} <- Spotify.search_random_track(credentials),
         track <- Trackable.to_track(random_track) do
      GenServer.call(via(game_uuid), {:start_game_session, track})
    else
      {:error, :game_session_not_found} -> {:error, :game_session_not_found}
      {:error, :no_credentials} -> {:error, :no_credentials}
      {:error, reason} -> {:error, reason}
      _status -> {:error, :game_already_started}
    end
  end

  @doc """
  Starts playback for the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `:spotify` - Provider identifier (only Spotify supported)

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :game_session_not_found}` - Game session does not exist
    * `{:error, :game_not_in_progress}` - Game is not in the correct status
    * `{:error, :no_credentials}` - No credentials available for session
    * `{:error, :no_current_track}` - No track is set for the current turn
    * `{:error, :no_track_uri}` - Track does not have Spotify URI in metadata

  ## Examples
      iex> {:ok, game} = GameSession.create_game_session("owner123", :spotify)
      iex> {:ok, _} = GameSession.start_game_session(game.uuid)
      iex> :ok = GameSession.set_credentials(game.uuid, credentials)
      iex> {:ok, updated_game} = GameSession.start_playback(game.uuid, :spotify)
      iex> updated_game.player.is_playback
      true

      iex> GameSession.start_playback("nonexistent", :spotify)
      {:error, :game_session_not_found}
  """
  @spec start_playback(String.t(), atom()) :: {:ok, Game.t()} | {:error, atom()}
  def start_playback(game_uuid, :spotify) do
    with {:ok, game} <- lookup_game_session(game_uuid),
         :in_progress <- Game.get_status(game),
         {:ok, credentials} <- get_credentials(game_uuid),
         %Track{meta: %{uri: track_uri}} <- Game.get_turn_track(game),
         {:ok, :playback_started} <- Spotify.start_playback(credentials, uris: [track_uri]) do
      GenServer.call(via(game_uuid), :start_playback)
    else
      {:error, :game_session_not_found} -> {:error, :game_session_not_found}
      {:error, :no_credentials} -> {:error, :no_credentials}
      {:error, reason} -> {:error, reason}
      %Track{meta: meta} when not is_map_key(meta, :uri) -> {:error, :no_track_uri}
      nil -> {:error, :no_current_track}
      _status -> {:error, :game_not_in_progress}
    end
  end

  @doc """
  Pauses playback for the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `:spotify` - Provider identifier (only Spotify supported)

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :game_session_not_found}` - Game session does not exist
    * `{:error, :game_not_in_progress}` - Game is not in the correct status
    * `{:error, :no_credentials}` - No credentials available for session

  ## Examples
      iex> {:ok, updated_game} = GameSession.pause_playback(game.uuid, :spotify)
      iex> updated_game.player.is_playback
      false

      iex> GameSession.pause_playback("nonexistent", :spotify)
      {:error, :game_session_not_found}
  """
  @spec pause_playback(String.t(), :spotify) :: {:ok, Game.t()} | {:error, atom()}
  def pause_playback(game_uuid, :spotify) do
    with {:ok, game} <- lookup_game_session(game_uuid),
         :in_progress <- Game.get_status(game),
         {:ok, credentials} <- get_credentials(game_uuid),
         {:ok, :playback_paused} <- Spotify.pause_playback(credentials) do
      GenServer.call(via(game_uuid), :pause_playback)
    else
      {:error, :game_session_not_found} -> {:error, :game_session_not_found}
      {:error, :no_credentials} -> {:error, :no_credentials}
      {:error, reason} -> {:error, reason}
      _status -> {:error, :game_not_in_progress}
    end
  end

  @doc """
  Advances the game turn to the next phase.

  ## Parameters
    * `game_uuid` - UUID of the game session

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :game_session_not_found}` - Game session does not exist
    * `{:error, :game_not_in_progress}` - Game is not in the correct status

  ## Examples
      iex> GameSession.next_phase("game123")
      {:ok, %Game{turn: %Turn{phase: :turn_ready}}}

      iex> GameSession.next_phase("nonexistent")
      {:error, :game_session_not_found}
  """
  @spec next_phase(String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def next_phase(game_uuid) do
    with {:ok, game} <- lookup_game_session(game_uuid),
         :in_progress <- Game.get_status(game) do
      GenServer.call(via(game_uuid), :next_phase)
    else
      {:error, :game_session_not_found} -> {:error, :game_session_not_found}
      _status -> {:error, :game_not_in_progress}
    end
  end

  @doc """
  Checks if the given user is the owner of the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `user_uuid` - UUID of the user to check

  ## Examples
      iex> GameSession.owner?("game123", "owner456")
      true

      iex> GameSession.owner?("game123", "participant789")
      false
  """
  @spec owner?(String.t(), String.t()) :: boolean()
  def owner?(game_uuid, user_uuid) do
    case lookup_game_session(game_uuid) do
      {:ok, game} -> Game.owner?(game, user_uuid)
      {:error, _} -> false
    end
  end

  @doc """
  Updates the provider for the game session.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `provider_data` - Map containing provider id and meta (%{id: atom(), meta: map()})

  ## Examples
      iex> GameSession.update_provider("game123", %{id: :spotify, meta: %{device_id: "abc123"}})
      {:ok, %Game{provider: %Provider{id: :spotify, meta: %{device_id: "abc123"}}}}

      iex> GameSession.update_provider("nonexistent", %{id: :spotify, meta: %{}})
      {:error, :game_session_not_found}
  """
  @spec update_provider(String.t(), map()) :: {:ok, Game.t()} | {:error, atom()}
  def update_provider(game_uuid, attrs) do
    with {:ok, game} <- lookup_game_session(game_uuid),
         %Provider{} = provider <- Provider.update(Game.get_provider(game), attrs) do
      GenServer.call(via(game_uuid), {:update_provider, provider})
    else
      error -> error
    end
  end

  @doc """
  Extends user timeline by adding the current turn track to specified position.

  Takes the track from the current turn and adds it to the user's timeline
  at the specified position. If no position is provided, adds at the beginning (position 0).

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `user_uuid` - UUID of the user whose timeline to extend
    * `position` - Position to insert the track (0-based index, defaults to 0)

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :game_session_not_found}` - Game session does not exist
    * `{:error, :no_current_track}` - No track is set for the current turn

  ## Examples
      iex> GameSession.extend_timeline("game123", "user456")
      {:ok, %Game{timelines: %{"user456" => [track_from_turn, existing_track]}}}

      iex> GameSession.extend_timeline("game123", "user456", 1)
      {:ok, %Game{timelines: %{"user456" => [existing_track, track_from_turn]}}}

      iex> GameSession.extend_timeline("nonexistent", "user456", 0)
      {:error, :game_session_not_found}
  """
  @spec extend_timeline(String.t(), String.t(), non_neg_integer()) :: {:ok, Game.t()} | {:error, atom()}
  def extend_timeline(game_uuid, user_uuid, position \\ 0)
      when is_binary(game_uuid) and is_binary(user_uuid) and is_integer(position) and position >= 0 do
    with {:ok, game} <- lookup_game_session(game_uuid),
         %Track{} = track <- Game.get_turn_track(game) do
      GenServer.call(via(game_uuid), {:extend_timeline, user_uuid, track, position})
    else
      {:error, :game_session_not_found} -> {:error, :game_session_not_found}
      nil -> {:error, :no_current_track}
    end
  end

  @doc """
  Reorders a track in user's timeline by moving it to a new position.

  Moves an existing track in the user's timeline to a different position.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `user_uuid` - UUID of the user whose timeline to reorder
    * `track_id` - ID of the track to move
    * `position` - New position for the track (0-based index)

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :game_session_not_found}` - Game session does not exist
    * `{:error, :track_not_found}` - Track not found in user's timeline

  ## Examples
      iex> GameSession.reorder_timeline("game123", "user456", "track_id", 2)
      {:ok, %Game{timelines: %{"user456" => [track1, track2, moved_track]}}}

      iex> GameSession.reorder_timeline("game123", "user456", "nonexistent_id", 0)
      {:error, :track_not_found}
  """
  @spec reorder_timeline(String.t(), String.t(), String.t(), non_neg_integer()) :: {:ok, Game.t()} | {:error, atom()}
  def reorder_timeline(game_uuid, user_uuid, track_id, position \\ 0)
      when is_binary(game_uuid) and is_binary(user_uuid) and is_binary(track_id) and is_integer(position) and
             position >= 0 do
    if game_session_exists?(game_uuid) do
      GenServer.call(via(game_uuid), {:reorder_timeline, user_uuid, track_id, position})
    else
      {:error, :game_session_not_found}
    end
  end

  @spec lookup_game_session(String.t()) :: {:ok, Game.t()} | {:error, :game_session_not_found}
  def lookup_game_session(game_uuid) do
    case Registry.lookup(Songy.Registry, game_uuid) do
      [{pid, _value}] -> GenServer.call(pid, :lookup_game_session, 1000)
      [] -> {:error, :game_session_not_found}
    end
  rescue
    _ -> {:error, :game_session_not_found}
  catch
    _, _ -> {:error, :game_session_not_found}
  end

  @doc """
  Checks if a game session process exists.

  Fast process existence check without retrieving the full game state.
  Use this when you only need to verify the session exists.

  ## Parameters
    * `game_uuid` - UUID of the game session

  ## Examples
      iex> GameSession.game_session_exists?("game123")
      true

      iex> GameSession.game_session_exists?("nonexistent")
      false
  """
  @spec game_session_exists?(String.t()) :: boolean()
  def game_session_exists?(game_uuid) do
    case Registry.lookup(Songy.Registry, game_uuid) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  @doc """
  Stores provider credentials in Registry for session access.

  Uses the Credentials protocol to extract credential data from any structure
  and stores it in Registry with a composite key for automatic cleanup.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `credentials` - Any structure that implements the Credentials protocol

  ## Examples
      iex> provider = Provider.new(:spotify, %{access_token: "token123"})
      iex> GameSession.set_credentials("game123", provider)
      :ok

      iex> GameSession.set_credentials("nonexistent", provider)
      {:error, :game_session_not_found}
  """
  @spec set_credentials(String.t(), any()) :: :ok | {:error, :game_session_not_found}
  def set_credentials(game_uuid, credentials) do
    if game_session_exists?(game_uuid) do
      GenServer.call(via(game_uuid), {:set_credentials, credentials})
    else
      {:error, :game_session_not_found}
    end
  end

  @doc """
  Retrieves stored credentials from Registry.

  ## Parameters
    * `game_uuid` - UUID of the game session

  ## Examples
      iex> GameSession.get_credentials("game123")
      {:ok, %{access_token: "token123", device_id: "device456"}}

      iex> GameSession.get_credentials("nonexistent")
      {:error, :game_session_not_found}

      iex> GameSession.get_credentials("game_without_credentials")
      {:error, :no_credentials}
  """
  @spec get_credentials(String.t()) :: {:ok, map()} | {:error, :no_credentials | :game_session_not_found}
  def get_credentials(game_uuid) do
    # First check if game session exists
    if game_session_exists?(game_uuid) do
      case Registry.lookup(Songy.Registry, {:credentials, game_uuid}) do
        [{_pid, credentials}] when not is_nil(credentials) -> {:ok, credentials}
        [{_pid, nil}] -> {:error, :no_credentials}
        [] -> {:error, :no_credentials}
      end
    else
      {:error, :game_session_not_found}
    end
  end

  def child_spec(game) do
    %{
      id: {__MODULE__, game.uuid},
      start: {__MODULE__, :start_link, [game]},
      restart: :temporary
    }
  end

  def start_link(%Game{} = game) do
    GenServer.start_link(
      __MODULE__,
      game,
      name: via(game.uuid)
    )
  end

  @impl GenServer
  def init(%Game{} = game) do
    Logger.info("Starting game session for game #{game.uuid}")

    SongyWeb.Presence.subscribe(game.uuid)

    {:ok, game}
  end

  @impl GenServer
  def handle_info({:participant_joined, user_uuid}, game) do
    user = User.get_user(user_uuid)

    if Game.empty?(game) do
      cancel_termination_timer(game.uuid)
    end

    case Game.add_participant(game, user) do
      {:ok, updated_game} ->
        {:noreply, updated_game, {:continue, {:init_participant_timeline, user_uuid}}}

      {:error, reason} ->
        Logger.warning("Failed to add participant #{user_uuid}: #{inspect(reason)}")
        {:noreply, game, {:continue, {:finalize_participant_initialization, user_uuid, :participant_failed}}}
    end
  end

  @impl GenServer
  def handle_info({:participant_left, user_uuid}, game) do
    case Game.remove_participant(game, user_uuid) do
      {:ok, updated_game} ->
        Phoenix.PubSub.local_broadcast(
          Songy.PubSub,
          "room:#{updated_game.uuid}",
          {:game_state_updated, updated_game}
        )

        if Game.empty?(updated_game) do
          schedule_termination(game.uuid)
        end

        {:noreply, updated_game}

      {:error, _reason} ->
        {:noreply, game}
    end
  end

  @impl GenServer
  def handle_info({:auto_terminate, game_uuid}, game) do
    Registry.unregister(Songy.Registry, {:termination_timer, game_uuid})

    if Game.empty?(game) do
      {:stop, :inactivity_timeout, game}
    else
      {:noreply, game}
    end
  end

  @impl GenServer
  def handle_continue({:init_participant_timeline, user_uuid}, game) do
    with [] <- Game.get_user_timeline(game, user_uuid),
         {:ok, credentials} <- get_credentials(game.uuid),
         {:ok, spotify_track} <- Spotify.search_random_track(credentials),
         track <- Trackable.to_track(spotify_track) do
      Logger.info("Init participant timeline with track '#{track.title}' by '#{track.artist}'")
      game = Game.extend_user_timeline(game, user_uuid, track)

      {:noreply, game, {:continue, {:finalize_participant_initialization, user_uuid, :timeline_initialized}}}
    else
      [%Track{} | _] ->
        Logger.info("Participant #{user_uuid} already has tracks in timeline, skipping initialization")
        {:noreply, game, {:continue, {:finalize_participant_initialization, user_uuid, :timeline_initialized}}}

      {:error, reason} ->
        Logger.warning("Failed to init timeline for user #{user_uuid}: #{inspect(reason)}")

        {:noreply, game,
         {:continue, {:finalize_participant_initialization, user_uuid, :timeline_initialization_failed}}}
    end
  end

  @impl GenServer
  def handle_continue({:finalize_participant_initialization, user_uuid, action}, game) do
    case action do
      :timeline_initialized ->
        Logger.info("Added participant #{user_uuid} with random track")

      :timeline_initialization_failed ->
        Logger.info("Added participant #{user_uuid} but failed to add random track")

      :participant_failed ->
        Logger.warning("Failed to add participant #{user_uuid}")
    end

    Phoenix.PubSub.local_broadcast(
      Songy.PubSub,
      "room:#{game.uuid}",
      {:game_state_updated, game}
    )

    {:noreply, game}
  end

  @impl GenServer
  def handle_call(:lookup_game_session, _from, game) do
    {:reply, {:ok, game}, game}
  end

  @impl GenServer
  def handle_call({:start_game_session, track}, _from, game) do
    with :waiting <- Game.get_status(game),
         {:ok, game_with_track} <- Game.set_turn_track(game, track),
         {:ok, started_game} <- Game.update_status(game_with_track) do
      {:reply, {:ok, started_game}, started_game}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, game}

      _other_status ->
        {:reply, {:error, :game_already_started}, game}
    end
  end

  @impl GenServer
  def handle_call(:start_playback, _from, game) do
    updated_game = Game.start_playback(game)
    {:reply, {:ok, updated_game}, updated_game}
  end

  @impl GenServer
  def handle_call(:pause_playback, _from, game) do
    updated_game = Game.pause_playback(game)
    {:reply, {:ok, updated_game}, updated_game}
  end

  @impl GenServer
  def handle_call(:next_phase, _from, game) do
    updated_game = Game.next_phase(game)

    Phoenix.PubSub.local_broadcast(
      Songy.PubSub,
      "room:#{updated_game.uuid}",
      {:game_state_updated, updated_game}
    )

    {:reply, {:ok, updated_game}, updated_game}
  end

  @impl GenServer
  def handle_call({:update_provider, provider}, _from, game) do
    updated_game = Game.update_provider(game, provider)

    {:reply, {:ok, updated_game}, updated_game}
  end

  @impl GenServer
  def handle_call({:remove_participant, participant_uuid}, _from, game) do
    case Game.remove_participant(game, participant_uuid) do
      {:ok, updated_game} ->
        Phoenix.PubSub.local_broadcast(
          Songy.PubSub,
          "room:#{updated_game.uuid}",
          {:game_state_updated, updated_game}
        )

        {:reply, {:ok, updated_game}, updated_game}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  @impl GenServer
  def handle_call({:set_credentials, credentials}, _from, game) do
    credential_data = Credentials.fetch(credentials)

    Registry.unregister(Songy.Registry, {:credentials, game.uuid})
    Registry.register(Songy.Registry, {:credentials, game.uuid}, credential_data)

    {:reply, :ok, game}
  end

  @impl GenServer
  def handle_call({:extend_timeline, user_uuid, track, position}, _from, game) do
    updated_game =
      game
      |> Game.extend_user_timeline(user_uuid, track, position)
      |> Game.next_phase()

    Logger.info("Extend timeline for user #{user_uuid} with track '#{track.id}' at position #{position}")

    Phoenix.PubSub.local_broadcast(
      Songy.PubSub,
      "room:#{updated_game.uuid}",
      {:game_state_updated, updated_game}
    )

    {:reply, {:ok, updated_game}, updated_game}
  end

  @impl GenServer
  def handle_call({:reorder_timeline, user_uuid, track_id, position}, _from, game) do
    case Game.reorder_user_timeline(game, user_uuid, track_id, position) do
      {:ok, updated_game} ->
        Logger.info("Reorder timeline for user #{user_uuid} with track ID #{track_id} at position #{position}")

        Phoenix.PubSub.local_broadcast(
          Songy.PubSub,
          "room:#{updated_game.uuid}",
          {:game_state_updated, updated_game}
        )

        {:reply, {:ok, updated_game}, updated_game}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  @impl GenServer
  def terminate(reason, game) do
    Logger.info("Game session #{game.uuid} terminated: #{inspect(reason)}")
    Registry.unregister(Songy.Registry, {:termination_timer, game.uuid})

    # Clean up stored credentials
    Registry.unregister(Songy.Registry, {:credentials, game.uuid})

    :ok
  end

  defp via(game_uuid) do
    {:via, Registry, {Songy.Registry, game_uuid}}
  end

  defp schedule_termination(game_uuid) do
    timeout = Application.get_env(:songy, :game_session_termination_timeout, :timer.minutes(3))

    timer_ref = Process.send_after(self(), {:auto_terminate, game_uuid}, timeout)
    Registry.register(Songy.Registry, {:termination_timer, game_uuid}, timer_ref)
    timer_ref
  end

  defp cancel_termination_timer(game_uuid) do
    case Registry.lookup(Songy.Registry, {:termination_timer, game_uuid}) do
      [{_pid, timer_ref}] ->
        Process.cancel_timer(timer_ref)
        Registry.unregister(Songy.Registry, {:termination_timer, game_uuid})
        :ok

      [] ->
        :ok
    end
  end
end
