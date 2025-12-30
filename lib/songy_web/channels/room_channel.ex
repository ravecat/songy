defmodule SongyWeb.RoomChannel do
  use SongyWeb, :channel

  alias Songy.Boundary.GameSession
  alias SongyWeb.Presence

  require Logger

  @room_prefix "room:"

  @impl true
  def join(_topic, _payload, socket) do
    user_id = socket.assigns.current_user_id

    {:ok, _} = Presence.track(socket, user_id, %{online_at: inspect(System.system_time(:second))})

    send(self(), :init_client_state)

    {:ok, socket}
  end

  @impl true
  def handle_info(:init_client_state, socket) do
    @room_prefix <> room_id = socket.topic

    case GameSession.get_state(room_id) do
      {:ok, game} ->
        push(socket, "state_updated", game)

      {:error, _} ->
        Logger.warning("Game session not found for room #{room_id}")
    end

    {:noreply, socket}
  end

  def handle_info({:game_state_updated, game}, socket) do
    broadcast(socket, "state_updated", game)

    {:noreply, socket}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_in("start_game", _payload, socket) do
    @room_prefix <> room_id = socket.topic

    case GameSession.start_game_session(room_id) do
      {:ok, game} ->
        broadcast(socket, "state_updated", game)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("start_playback", _payload, socket) do
    @room_prefix <> room_id = socket.topic
    current_user_id = socket.assigns.current_user_id

    case GameSession.start_playback(room_id, current_user_id) do
      {:ok, game} ->
        broadcast(socket, "state_updated", game)
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
      {:ok, game} ->
        broadcast(socket, "state_updated", game)
        {:reply, :ok, socket}

      {:error, reason} ->
        Logger.warning("Pause playback failed: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("get_provider", _payload, socket) do
    user_id = socket.assigns.current_user_id

    case Songy.Providers.lookup(:providers, user_id) do
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

    case Songy.Providers.lookup(:providers, user_id) do
      {:ok, current_data} ->
        attrs = for {key, val} <- payload, into: %{}, do: {String.to_atom(key), val}
        updated_data = Songy.Core.Provider.Spotify.update(current_data, attrs)
        :ok = Songy.Providers.update(:providers, user_id, updated_data)
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
  def handle_in("next_phase", _payload, socket) do
    @room_prefix <> room_id = socket.topic

    case GameSession.next_phase(room_id) do
      {:ok, game} ->
        broadcast(socket, "state_updated", game)
        {:reply, :ok, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("make_assumption", %{"position" => position}, socket) do
    @room_prefix <> room_id = socket.topic
    current_user_id = socket.assigns.current_user_id

    case GameSession.make_assumption(room_id, current_user_id, position) do
      {:ok, game} ->
        broadcast(socket, "state_updated", game)

        {:reply, :ok, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("reorder_timeline", %{"position" => position}, socket) do
    @room_prefix <> room_id = socket.topic
    user_id = socket.assigns.current_user_id

    case GameSession.reorder_timeline(room_id, user_id, position) do
      {:ok, game} ->
        broadcast(socket, "state_updated", game)

        {:reply, :ok, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in(event, _payload, socket) do
    {:reply, {:error, %{reason: "unknown_event", event: event}}, socket}
  end
end
