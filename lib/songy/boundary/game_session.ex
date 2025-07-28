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
    * `start_playback/3` - Starts playback with provider and credentials
    * `pause_playback/3` - Pauses playback and updates internal state
    * `end_game_session/1` - Terminates a game session process
    * `owner?/2` - Checks if a user is the owner of a game session
    * `update_provider/2` - Updates the provider for a game session (owner only)
    * `set_credentials/2` - Stores provider credentials in Registry for session access
    * `get_credentials/1` - Retrieves stored credentials from Registry

  ## Process Management

  Game sessions are registered in `Songy.Registry` using their UUID as the key.
  This allows for efficient lookup and ensures uniqueness across all sessions.

  Sessions are supervised by `Songy.Supervisor.GameSession` and will be
  automatically restarted if they crash unexpectedly.
  """

  use GenServer

  alias Songy.Core.{Game, User, Provider}
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
    case lookup_game_session(game_uuid) do
      {:ok, _} ->
        GenServer.stop(via(game_uuid), reason, timeout)

      {:error, _} ->
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
    case lookup_game_session(game_uuid) do
      {:ok, _} ->
        GenServer.call(via(game_uuid), {:remove_participant, participant_uuid})

      {:error, _} ->
        {:error, :not_found}
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
      {:error, :not_found}
  """
  @spec start_game_session(String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def start_game_session(game_uuid) do
    case lookup_game_session(game_uuid) do
      {:ok, _} ->
        GenServer.call(via(game_uuid), :start_game_session)

      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Starts playback for the game session.

  Updates the internal player state to indicate that playback is active.
  This function only works when the game is in `:in_progress` status.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `provider` - Provider identifier atom (e.g., :spotify)
    * `credentials` - Provider credentials for API calls

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :not_found}` - Game session does not exist
    * `{:error, :game_not_in_progress}` - Game is not in the correct status

  ## Examples
      iex> {:ok, game} = GameSession.create_game_session("owner123", :spotify)
      iex> {:ok, _} = GameSession.start_game_session(game.uuid)
      iex> credentials = %{access_token: "token123"}
      iex> {:ok, updated_game} = GameSession.start_playback(game.uuid, :spotify, credentials)
      iex> updated_game.player.is_playback
      true

      iex> GameSession.start_playback("nonexistent", :spotify, credentials)
      {:error, :not_found}
  """
  @spec start_playback(String.t(), atom(), map()) :: {:ok, Game.t()} | {:error, atom()}
  def start_playback(game_uuid, provider, credentials) do
    case lookup_game_session(game_uuid) do
      {:ok, _} ->
        GenServer.call(via(game_uuid), {:start_playback, provider, credentials})

      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Pauses playback for the game session.

  Updates the internal player state to indicate that playback is paused.
  This function only works when the game is in `:in_progress` status.

  ## Parameters
    * `game_uuid` - UUID of the game session
    * `provider` - Provider identifier atom (e.g., :spotify)
    * `credentials` - Provider credentials for API calls

  ## Returns
    * `{:ok, game}` - Success with updated game state
    * `{:error, :not_found}` - Game session does not exist
    * `{:error, :game_not_in_progress}` - Game is not in the correct status

  ## Examples
      iex> {:ok, game} = GameSession.create_game_session("owner123", :spotify)
      iex> {:ok, _} = GameSession.start_game_session(game.uuid)
      iex> credentials = %{access_token: "token123"}
      iex> {:ok, _} = GameSession.start_playback(game.uuid, :spotify, credentials)
      iex> {:ok, updated_game} = GameSession.pause_playback(game.uuid, :spotify, credentials)
      iex> updated_game.player.is_playback
      false

      iex> GameSession.pause_playback("nonexistent", :spotify, credentials)
      {:error, :not_found}
  """
  @spec pause_playback(String.t(), atom(), map()) :: {:ok, Game.t()} | {:error, atom()}
  def pause_playback(game_uuid, provider, credentials) do
    case lookup_game_session(game_uuid) do
      {:ok, _} ->
        GenServer.call(via(game_uuid), {:pause_playback, provider, credentials})

      {:error, _} ->
        {:error, :not_found}
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
      {:error, :not_found}
  """
  @spec update_provider(String.t(), map()) :: {:ok, Game.t()} | {:error, atom()}
  def update_provider(game_uuid, attrs) do
    with {:ok, game} <- lookup_game_session(game_uuid),
         %Provider{} = provider <- Provider.update(game.provider, attrs) do
      GenServer.call(via(game_uuid), {:update_provider, provider})
    else
      error -> error
    end
  end

  @spec lookup_game_session(String.t()) :: {:ok, Game.t()} | {:error, :not_found}
  def lookup_game_session(game_uuid) do
    case Registry.lookup(Songy.Registry, game_uuid) do
      [{pid, _value}] -> GenServer.call(pid, :lookup_game_session, 1000)
      [] -> {:error, :not_found}
    end
  rescue
    _ -> {:error, :not_found}
  catch
    _, _ -> {:error, :not_found}
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
      {:error, :not_found}
  """
  @spec set_credentials(String.t(), any()) :: :ok | {:error, :not_found}
  def set_credentials(game_uuid, credentials) do
    case lookup_game_session(game_uuid) do
      {:ok, _} ->
        GenServer.call(via(game_uuid), {:set_credentials, credentials})

      error ->
        error
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
      {:error, :not_found}
  """
  @spec get_credentials(String.t()) :: {:ok, map()} | {:error, :not_found | :no_credentials}
  def get_credentials(game_uuid) do
    case lookup_game_session(game_uuid) do
      {:ok, _} ->
        GenServer.call(via(game_uuid), :get_credentials)

      error ->
        error
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

    case Game.add_participant(game, user) do
      {:ok, updated_game} ->
        Phoenix.PubSub.local_broadcast(
          Songy.PubSub,
          "room:#{updated_game.uuid}",
          {:game_state_updated, updated_game}
        )

        if Game.empty?(game) do
          cancel_termination_timer(game.uuid)
        end

        {:noreply, updated_game}

      {:error, _reason} ->
        {:noreply, game}
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
  def handle_call(:lookup_game_session, _from, game) do
    {:reply, {:ok, game}, game}
  end

  @impl GenServer
  def handle_call(:start_game_session, _from, game) do
    case game.status do
      :waiting ->
        updated_game = %{game | status: :in_progress}
        {:reply, {:ok, updated_game}, updated_game}

      _ ->
        {:reply, {:error, :game_already_started}, game}
    end
  end

  @impl GenServer
  def handle_call({:start_playback, :spotify, credentials}, _from, game) do
    with :in_progress <- game.status,
         {:ok, :playback_started} <- Spotify.start_playback(credentials),
         %Game{} = updated_game <- Game.start_playback(game) do
      {:reply, {:ok, updated_game}, updated_game}
    else
      _ ->
        {:reply, {:error, :game_not_in_progress}, game}
    end
  end

  @impl GenServer
  def handle_call({:pause_playback, :spotify, credentials}, _from, game) do
    with :in_progress <- game.status,
         {:ok, :playback_paused} <- Spotify.pause_playback(credentials),
         %Game{} = updated_game <- Game.pause_playback(game) do
      {:reply, {:ok, updated_game}, updated_game}
    else
      _ ->
        {:reply, {:error, :game_not_in_progress}, game}
    end
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
  def handle_call(:get_credentials, _from, game) do
    case Registry.lookup(Songy.Registry, {:credentials, game.uuid}) do
      [{_pid, credentials}] -> {:reply, {:ok, credentials}, game}
      [] -> {:reply, {:error, :no_credentials}, game}
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
