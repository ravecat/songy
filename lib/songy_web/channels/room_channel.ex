defmodule SongyWeb.RoomChannel do
  use SongyWeb, :channel

  alias SongyWeb.Presence
  alias Songy.Boundary.{GameSession, Spotify}

  require Logger

  @room_prefix "room:"

  @impl true
  def join(@room_prefix <> _, _payload, socket) do
    send(self(), :init_state)
    send(self(), :track_presence)

    {:ok, socket}
  end

  @impl true
  def handle_info(:init_state, socket) do
    @room_prefix <> room_id = socket.topic

    case GameSession.lookup_game_session(room_id) do
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

  def handle_info({:game_state_updated, game}, socket) do
    broadcast(socket, "state_updated", game)

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
  def handle_in(
        "start_playback",
        _payload,
        %{assigns: %{provider: %{id: provider, meta: credentials}}} = socket
      ) do
    @room_prefix <> room_id = socket.topic
    current_user_uuid = socket.assigns.current_user_uuid

    with true <- GameSession.owner?(room_id, current_user_uuid),
         {:ok, game} <- GameSession.start_playback(room_id, provider, credentials) do
      broadcast(socket, "state_updated", game)
      {:reply, :ok, socket}
    else
      {:error, reason} ->
        Logger.warning("Start playback failed: #{inspect(reason)}")
        {:noreply, socket}

      other ->
        Logger.warning("Start playback failed with: #{inspect(other)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in(
        "pause_playback",
        _payload,
        %{assigns: %{provider: %{id: provider, meta: credentials}}} = socket
      ) do
    @room_prefix <> room_id = socket.topic
    current_user_uuid = socket.assigns.current_user_uuid

    with true <- GameSession.owner?(room_id, current_user_uuid),
         {:ok, game} <- GameSession.pause_playback(room_id, provider, credentials) do
      broadcast(socket, "state_updated", game)
      {:reply, :ok, socket}
    else
      {:error, reason} ->
        Logger.warning("Pause playback failed: #{inspect(reason)}")
        {:noreply, socket}

      other ->
        Logger.warning("Pause playback failed with: #{inspect(other)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in(
        "update_provider",
        %{"device_id" => _device_id} = payload,
        %{assigns: %{provider: %{id: :spotify, meta: credentials}}} = socket
      ) do
    @room_prefix <> room_id = socket.topic
    current_user_uuid = socket.assigns.current_user_uuid

    with true <- GameSession.owner?(room_id, current_user_uuid),
         {:ok, _game} <- GameSession.update_provider(room_id, payload),
         {:ok, :playback_transferred} <- Spotify.transfer_playback(credentials, payload) do
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
    @room_prefix <> room_id = socket.topic
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
