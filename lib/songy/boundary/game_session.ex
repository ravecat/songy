defmodule Songy.Boundary.GameSession do
  @moduledoc """
  GenServer for managing game session state and player interactions.

  Each game session is a separate process that maintains the state of
  an active game room. Sessions are dynamically created and supervised
  by the GameSession supervisor.

  ## Public API

    * `create_game_session/1` - Creates and starts a new game session process with owner
    * `remove_participant/2` - Removes a participant from an existing game session
    * `lookup_game_session/1` - Retrieves the current state of a game session
    * `start_game_session/1` - Starts the game by changing its status to in_progress
    * `start_playback/1` - Starts playback for the game session
    * `pause_playback/1` - Pauses playback for the game session
    * `end_game_session/1` - Terminates a game session process
    * `owner?/2` - Checks if a user is the owner of a game session
    * `set_credentials/2` - Stores provider credentials in Registry for session access
    * `make_assumption/2` - Adds current turn track to active timeline at beginning (position 0)
    * `make_assumption/3` - Adds current turn track to active timeline at specified position
    * `reorder_timeline/4` - Reorders a track in user's timeline to new position

  ## Process Management

  Game sessions are registered in `Songy.Registry` using their UUID as the key.
  This allows for efficient lookup and ensures uniqueness across all sessions.

  Sessions are supervised by `Songy.Supervisor.GameSession` and will be
  automatically restarted if they crash unexpectedly.
  """

  use GenServer

  alias Songy.Boundary.Spotify
  alias Songy.Core.Game
  alias Songy.Core.Track
  alias Songy.Core.Trackable
  alias Songy.Core.User

  require Logger

  @doc """
  Creates and starts a new game session process with specified owner.

  Generates a new game with a random UUID and starts the session process.

  ## Parameters
    * `owner_uuid` - UUID of the user who will own the game room

  ## Examples
      iex> GameSession.create_game_session("user123")
      {:ok, %Game{uuid: "a1b2c3", participants: [], owner_uuid: "user123"}}

      iex> GameSession.create_game_session("invalid")
      {:error, :process_start_failed}
  """
  @spec create_game_session(String.t()) :: {:ok, Game.t()} | {:error, term()}
  def create_game_session(owner_uuid) when is_binary(owner_uuid) do
    with game <- Game.new(owner_uuid),
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
         {:ok, credentials} <- get_provider_meta(game.owner_uuid),
         {:ok, random_track} <- Spotify.search_random_track(credentials),
         track <- Trackable.to_track(random_track) do
      GenServer.call(via(game_uuid), {:start_game_session, track})
    else
      {:error, :game_session_not_found} -> {:error, :game_session_not_found}
      {:error, reason} -> {:error, reason}
      _status -> {:error, :game_already_started}
    end
  end

  @doc """
  Starts playback for the game session.

  Looks up provider credentials from ETS using the game owner's user ID.

  ## Parameters
    * `game_uuid` - UUID of the game session

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :game_session_not_found}` - Game session does not exist
    * `{:error, :game_not_in_progress}` - Game is not in the correct status
    * `{:error, :no_credentials}` - No credentials available for session
    * `{:error, :no_current_track}` - No track is set for the current turn
    * `{:error, :no_track_uri}` - Track does not have Spotify URI in metadata

  ## Examples
      iex> {:ok, game} = GameSession.create_game_session("owner123")
      iex> {:ok, _} = GameSession.start_game_session(game.id)
      iex> :ok = GameSession.set_credentials(game.id, credentials)
      iex> {:ok, updated_game} = GameSession.start_playback(game.id)
      iex> updated_game.player.is_playback
      true

      iex> GameSession.start_playback("nonexistent")
      {:error, :game_session_not_found}
  """
  @spec start_playback(String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def start_playback(game_uuid) do
    with {:ok, game} <- lookup_game_session(game_uuid),
         :in_progress <- Game.get_status(game),
         {:ok, meta} <- get_provider_meta(game.owner_uuid),
         %Track{meta: %{uri: track_uri}} <- Game.get_turn_track(game),
         {:ok, :playback_started} <- Spotify.start_playback(meta, uris: [track_uri], device_id: meta.device_id) do
      GenServer.call(via(game_uuid), :start_playback)
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :no_current_track}
      %Track{meta: meta} when not is_map_key(meta, :uri) -> {:error, :no_current_track}
      _status -> {:error, :game_not_in_progress}
    end
  end

  @doc """
  Pauses playback for the game session.

  Looks up provider credentials from ETS using the game owner's user ID.

  ## Parameters
    * `game_uuid` - UUID of the game session

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :game_session_not_found}` - Game session does not exist
    * `{:error, :game_not_in_progress}` - Game is not in the correct status
    * `{:error, :no_credentials}` - No credentials available for session

  ## Examples
      iex> {:ok, updated_game} = GameSession.pause_playback(game.id)
      iex> updated_game.player.is_playback
      false

      iex> GameSession.pause_playback("nonexistent")
      {:error, :game_session_not_found}
  """
  @spec pause_playback(String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def pause_playback(game_uuid) do
    with {:ok, game} <- lookup_game_session(game_uuid),
         :in_progress <- Game.get_status(game),
         {:ok, credentials} <- get_provider_meta(game.owner_uuid),
         {:ok, :playback_paused} <- Spotify.pause_playback(credentials) do
      GenServer.call(via(game_uuid), :pause_playback)
    else
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
      {:ok, %Game{turn: %Turn{phase: :ready}}}

      iex> GameSession.next_phase("nonexistent")
      {:error, :game_session_not_found}
  """
  @spec next_phase(String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def next_phase(game_uuid) when is_binary(game_uuid) do
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
  Makes an assumption by adding the current turn track to active timeline at specified position.

  Takes the track from the current turn and adds it to the active timeline (turn.timeline)
  at the specified position. If no position is provided, adds at the beginning (position 0).
  This represents a user's assumption about what song is currently playing.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `user_uuid` - UUID of the user making the assumption
    * `position` - Position to insert the track (0-based index, defaults to 0)

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :game_session_not_found}` - Game session does not exist
    * `{:error, :no_current_track}` - No track is set for the current turn

  ## Examples
      iex> GameSession.make_assumption("game123", "user456")
      {:ok, %Game{turn: %{timeline: [track_from_turn, existing_track]}}}

      iex> GameSession.make_assumption("game123", "user456", 1)
      {:ok, %Game{turn: %{timeline: [existing_track, track_from_turn]}}}

      iex> GameSession.make_assumption("nonexistent", "user456", 0)
      {:error, :game_session_not_found}
  """
  @spec make_assumption(String.t(), String.t(), non_neg_integer()) :: {:ok, Game.t()} | {:error, atom()}
  def make_assumption(game_uuid, user_uuid, position \\ 0)
      when is_binary(game_uuid) and is_binary(user_uuid) and is_integer(position) and position >= 0 do
    if game_session_exists?(game_uuid) do
      GenServer.call(via(game_uuid), {:make_assumption, user_uuid, position})
    else
      {:error, :game_session_not_found}
    end
  end

  @doc """
  Reorders a track in the active timeline by moving it to a new position.
  Uses the user's assumption to find and move their track.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `user_uuid` - UUID of the user whose track to move
    * `position` - New position for the track (0-based index)

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :game_session_not_found}` - Game session does not exist
    * `{:error, :user_assumption_not_found}` - User has no assumption in timeline
    * `{:error, :no_turn}` - Game has no active turn

  ## Examples
      iex> GameSession.reorder_timeline("game123", "user456", 2)
      {:ok, %Game{turn: %{timeline: [track1, track2, moved_track]}}}

      iex> GameSession.reorder_timeline("game123", "nonexistent_user", 0)
      {:error, :user_assumption_not_found}
  """
  @spec reorder_timeline(String.t(), String.t(), non_neg_integer()) :: {:ok, Game.t()} | {:error, atom()}
  def reorder_timeline(game_uuid, user_uuid, position \\ 0)
      when is_binary(game_uuid) and is_binary(user_uuid) and
             position >= 0 do
    if game_session_exists?(game_uuid) do
      GenServer.call(via(game_uuid), {:reorder_timeline, user_uuid, position})
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

  @spec get_provider_meta(String.t()) :: {:ok, map()} | {:error, :no_credentials}
  defp get_provider_meta(owner_uuid) when is_binary(owner_uuid) do
    case Songy.Providers.lookup(:providers, owner_uuid) do
      {:ok, {_provider, credentials}} -> {:ok, credentials}
      {:error, :not_found} -> {:error, :no_credentials}
      {:error, _reason} -> {:error, :no_credentials}
    end
  end

  def child_spec(game) do
    %{
      id: {__MODULE__, game.id},
      start: {__MODULE__, :start_link, [game]},
      restart: :temporary
    }
  end

  def start_link(%Game{} = game) do
    GenServer.start_link(
      __MODULE__,
      game,
      name: via(game.id)
    )
  end

  @impl GenServer
  def init(%Game{} = game) do
    Logger.info("Starting game session for game #{game.id}")

    SongyWeb.Presence.subscribe(game.id)

    {:ok, game}
  end

  @impl GenServer
  def handle_info({:participant_joined, user_uuid}, game) do
    user = User.get_user(user_uuid)

    if Game.empty?(game) do
      cancel_termination_timer(game.id)
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
          "room:#{updated_game.id}",
          {:game_state_updated, updated_game}
        )

        if Game.empty?(updated_game) do
          schedule_termination(game.id)
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
  def handle_info(:next_phase, %{turn: %{phase: :challenging}} = game) do
    Logger.info("Challenging phase timeout reached for game #{game.id}, advancing to results")

    updated_game = Game.next_phase(game)

    Phoenix.PubSub.local_broadcast(
      Songy.PubSub,
      "room:#{updated_game.id}",
      {:game_state_updated, updated_game}
    )

    {:noreply, updated_game}
  end

  @impl GenServer
  def handle_info(event, game) do
    Logger.warning("Received unexpected message #{inspect(event)} for game #{game.id}")
    {:noreply, game}
  end

  @impl GenServer
  def handle_continue({:init_participant_timeline, user_uuid}, game) do
    with [] <- Game.get_user_timeline(game, user_uuid),
         {:ok, credentials} <- get_provider_meta(game.owner_uuid),
         {:ok, spotify_track} <- Spotify.search_random_track(credentials),
         track <- Trackable.to_track(spotify_track) do
      Logger.info("Init participant timeline with track '#{track.title}' by '#{track.artist}'")
      game = Game.init_user_timeline(game, user_uuid, track)

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
      "room:#{game.id}",
      {:game_state_updated, game}
    )

    {:noreply, game}
  end

  @impl GenServer
  def handle_continue(:schedule_challenging_timeout, game) do
    timeout = Application.fetch_env!(:songy, :challenging_phase_timeout)

    Process.send_after(self(), :next_phase, timeout)

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
  def handle_call(:next_phase, _from, %{turn: %{phase: :steady}} = game) do
    updated_game = Game.next_phase(game)

    Phoenix.PubSub.local_broadcast(
      Songy.PubSub,
      "room:#{updated_game.id}",
      {:game_state_updated, updated_game}
    )

    {:reply, {:ok, updated_game}, updated_game, {:continue, :schedule_challenging_timeout}}
  end

  @impl GenServer
  def handle_call(:next_phase, _from, %{turn: %{phase: :results}} = game) do
    with {:ok, credentials} <- get_provider_meta(game.owner_uuid),
         {:ok, spotify_track} <- Spotify.search_random_track(credentials),
         %Track{} = track <- Trackable.to_track(spotify_track),
         {:ok, :playback_paused} <- Spotify.pause_playback(credentials),
         game <- Game.pause_playback(game),
         game <- Game.next_phase(game),
         {:ok, game} <- Game.set_turn_track(game, track) do
      Phoenix.PubSub.local_broadcast(
        Songy.PubSub,
        "room:#{game.id}",
        {:game_state_updated, game}
      )

      {:reply, {:ok, game}, game}
    else
      {:error, reason} -> {:reply, {:error, reason}, game}
    end
  end

  @impl GenServer
  def handle_call(:next_phase, _from, game) do
    updated_game = Game.next_phase(game)

    Phoenix.PubSub.local_broadcast(
      Songy.PubSub,
      "room:#{updated_game.id}",
      {:game_state_updated, updated_game}
    )

    {:reply, {:ok, updated_game}, updated_game}
  end

  @impl GenServer
  def handle_call({:remove_participant, participant_uuid}, _from, game) do
    case Game.remove_participant(game, participant_uuid) do
      {:ok, updated_game} ->
        Phoenix.PubSub.local_broadcast(
          Songy.PubSub,
          "room:#{updated_game.id}",
          {:game_state_updated, updated_game}
        )

        {:reply, {:ok, updated_game}, updated_game}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  @impl GenServer
  def handle_call({:make_assumption, user_uuid, position}, _from, game) do
    updated_game = Game.extend_active_timeline(game, user_uuid, position)

    Logger.info("Make assumption for user #{user_uuid} at position #{position}")

    Phoenix.PubSub.local_broadcast(
      Songy.PubSub,
      "room:#{updated_game.id}",
      {:game_state_updated, updated_game}
    )

    {:reply, {:ok, updated_game}, updated_game}
  end

  @impl GenServer
  def handle_call({:reorder_timeline, user_uuid, position}, _from, game) do
    case Game.reorder_active_timeline(game, user_uuid, position) do
      {:ok, updated_game} ->
        Logger.info("Reorder active timeline for user #{user_uuid} at position #{position}")

        Phoenix.PubSub.local_broadcast(
          Songy.PubSub,
          "room:#{updated_game.id}",
          {:game_state_updated, updated_game}
        )

        {:reply, {:ok, updated_game}, updated_game}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  @impl GenServer
  def terminate(reason, game) do
    Logger.info("Game session #{game.id} terminated: #{inspect(reason)}")
    Registry.unregister(Songy.Registry, {:termination_timer, game.id})

    # Clean up stored credentials
    Registry.unregister(Songy.Registry, {:credentials, game.id})

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
