defmodule SongyWeb.RoomChannel do
  use SongyWeb, :channel

  alias Songy.Boundary.GameSession
  alias SongyWeb.Presence

  require Logger

  @room_prefix "room:"

  @impl true
  def join(topic, _payload, socket) do
    @room_prefix <> room_id = topic
    current_user_id = socket.assigns.current_user_id

    case GameSession.get_state(room_id) do
      {:ok, _game} ->
        {:ok, _} =
          Presence.track(socket, current_user_id, %{online_at: inspect(System.system_time(:second))})

        send(self(), :init_client_state)

        {:ok, socket}

      {:error, reason} ->
        Logger.warning("Join failed for #{room_id}: #{inspect(reason)}")

        {:error, %{reason: "game_not_found"}}
    end
  end

  @impl true
  def handle_info(:init_client_state, socket) do
    @room_prefix <> room_id = socket.topic
    current_user_id = socket.assigns.current_user_id

    case GameSession.get_state(room_id) do
      {:ok, game} ->
        permissions = Songy.Authorization.permissions(game, current_user_id)
        push(socket, "state", %{game: game, permissions: permissions})

      {:error, reason} ->
        Logger.warning("Failed to join #{room_id}: #{inspect(reason)}")
    end

    {:noreply, socket}
  end

  def handle_info({:state, game}, socket) do
    current_user_id = socket.assigns.current_user_id
    permissions = Songy.Authorization.permissions(game, current_user_id)
    push(socket, "state", %{game: game, permissions: permissions})

    {:noreply, socket}
  end

  def handle_info({:timer, remaining}, socket) do
    push(socket, "timer", %{remaining: remaining})
    {:noreply, socket}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_in("start_game", _payload, socket) do
    @room_prefix <> room_id = socket.topic
    current_user_id = socket.assigns.current_user_id

    case GameSession.start_game_session(room_id, current_user_id) do
      {:ok, _game} ->
        {:noreply, socket}

      {:error, reason} ->
        Logger.warning("Failed to start game session #{room_id}: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("start_playback", _payload, socket) do
    @room_prefix <> room_id = socket.topic
    current_user_id = socket.assigns.current_user_id

    case GameSession.start_playback(room_id, current_user_id) do
      {:ok, _game} ->
        {:reply, :ok, socket}

      {:error, reason} ->
        Logger.warning("Start playback failed with: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("pause_playback", _payload, socket) do
    @room_prefix <> room_id = socket.topic
    current_user_id = socket.assigns.current_user_id

    case GameSession.pause_playback(room_id, current_user_id) do
      {:ok, _game} ->
        {:reply, :ok, socket}

      {:error, reason} ->
        Logger.warning("Pause playback failed: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("get_provider", _payload, socket) do
    user_id = socket.assigns.current_user_id

    case Songy.Providers.lookup(user_id) do
      {:ok, %Songy.Core.Provider.Spotify{access_token: token}} when not is_nil(token) ->
        {:reply, {:ok, %{token: token}}, socket}

      {:ok, _other_provider} ->
        {:reply, {:error, %{reason: "invalid_credentials"}}, socket}

      {:error, _reason} ->
        {:reply, {:error, %{reason: "invalid_credentials"}}, socket}
    end
  end

  @impl true
  def handle_in("update_provider", payload, socket) do
    user_id = socket.assigns.current_user_id

    case Songy.Providers.lookup(user_id) do
      {:ok, current_data} ->
        attrs = for {key, val} <- payload, into: %{}, do: {String.to_atom(key), val}
        updated_data = Songy.Core.Provider.Spotify.update(current_data, attrs)
        :ok = Songy.Providers.update(user_id, updated_data)
        Logger.debug("Updated provider data for user #{user_id} with #{inspect(payload)}")
        {:reply, :ok, socket}

      {:error, _reason} ->
        Logger.warning("Failed to update provider for user #{user_id}: user not found in ETS")

        {:reply, {:error, %{reason: "provider_not_found"}}, socket}
    end
  end

  @impl true
  def handle_in("get_current_user", _payload, socket) do
    user_id = socket.assigns.current_user_id
    user = Songy.Core.User.get_user(user_id)
    {:reply, {:ok, user}, socket}
  end

  @impl true
  def handle_in("advance_turn", _payload, socket) do
    @room_prefix <> room_id = socket.topic
    current_user_id = socket.assigns.current_user_id

    case GameSession.advance_turn(room_id, current_user_id) do
      {:ok, _game} ->
        {:reply, :ok, socket}

      {:error, reason} ->
        Logger.warning("Failed to advance phase for game #{room_id}: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("make_assumption", %{"position" => position}, socket) do
    @room_prefix <> room_id = socket.topic
    current_user_id = socket.assigns.current_user_id

    with {position, ""} <- Integer.parse(to_string(position)),
         {:ok, _game} <- GameSession.make_assumption(room_id, current_user_id, position) do
      {:reply, :ok, socket}
    else
      :error ->
        Logger.warning("Failed to make assumption in game #{room_id}: invalid position #{inspect(position)}")
        {:noreply, socket}

      {:error, reason} ->
        Logger.warning("Failed to make assumption in game #{room_id}: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in(event, _payload, socket) do
    {:reply, {:error, %{reason: "unknown_event", event: event}}, socket}
  end
end
