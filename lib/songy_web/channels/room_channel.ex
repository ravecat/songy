defmodule SongyWeb.RoomChannel do
  use SongyWeb, :channel

  alias SongyWeb.Presence
  alias Songy.Boundary.GameSession
  alias Songy.Boundary.Spotify

  require Logger

  @impl true
  def join("room:" <> _, _payload, socket) do
    send(self(), :init_state)
    send(self(), :track_presence)

    {:ok, socket}
  end

  @impl true
  def handle_info(:init_state, socket) do
    "room:" <> room_id = socket.topic

    case GameSession.get_game_session(room_id) do
      {:ok, game} ->
        push(socket, "state_updated", game)

      {:error, _} ->
        Logger.warning("Game session not found for room #{room_id}")
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:track_presence, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.current_user_uuid, %{
        online_at: inspect(System.system_time(:second))
      })

    {:noreply, socket}
  end

  @impl true
  def handle_info({:participant_joined, user_uuid}, socket) do
    "room:" <> room_id = socket.topic
    Logger.info("Participant #{user_uuid} joined room #{room_id}")

    case GameSession.add_participant(room_id, user_uuid) do
      {:ok, game} ->
        broadcast(socket, "state_updated", game)
        {:noreply, socket}

      {:error, reason} ->
        Logger.warning("Failed to add participant #{user_uuid}: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:participant_left, user_uuid}, socket) do
    "room:" <> room_id = socket.topic
    Logger.info("Participant #{user_uuid} left room #{room_id}")

    case GameSession.remove_participant(room_id, user_uuid) do
      {:ok, game} ->
        broadcast(socket, "state_updated", game)
        {:noreply, socket}

      {:error, reason} ->
        Logger.warning("Failed to remove participant #{user_uuid}: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("start_game", _payload, socket) do
    "room:" <> room_id = socket.topic

    case GameSession.start_game_session(room_id) do
      {:ok, game} ->
        broadcast(socket, "state_updated", game)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in(
        "update_provider",
        %{"device_id" => _device_id} = payload,
        %{assigns: %{provider: %{id: :spotify} = provider}} = socket
      ) do
    "room:" <> room_id = socket.topic
    current_user_uuid = socket.assigns.current_user_uuid

    with true <- GameSession.owner?(room_id, current_user_uuid),
         {:ok, _game} <- GameSession.update_provider(room_id, payload),
         {:ok, :transferred} <- Spotify.transfer_playback(provider, payload) do
      {:reply, :ok, socket}
    else
      {:error, _reason} ->
        {:noreply, socket}
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("update_provider", payload, socket) do
    "room:" <> room_id = socket.topic
    current_user_uuid = socket.assigns.current_user_uuid

    with true <- GameSession.owner?(room_id, current_user_uuid),
         {:ok, _game} <- GameSession.update_provider(room_id, payload) do
      {:reply, :ok, socket}
    else
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("get_spotify_token", _payload, socket) do
    case socket.assigns[:provider] do
      %{id: :spotify, meta: %{access_token: token}} when not is_nil(token) ->
        {:reply, {:ok, %{token: token}}, socket}

      _ ->
        {:reply, {:error, %{reason: "invalid_credentials"}}, socket}
    end
  end

  @impl true
  def handle_in(event, _payload, socket) do
    {:reply, {:error, %{reason: "unknown_event", event: event}}, socket}
  end
end
