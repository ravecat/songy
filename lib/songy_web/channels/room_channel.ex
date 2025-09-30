defmodule SongyWeb.RoomChannel do
  use SongyWeb, :channel

  alias Songy.Boundary.GameSession
  alias SongyWeb.Presence

  require Logger

  @room_prefix "room:"

  @impl true
  def join(@room_prefix <> _, _payload, socket) do
    send(self(), :init_client_state)
    send(self(), :track_presence)

    {:ok, socket}
  end

  @impl true
  def handle_info(:init_client_state, socket) do
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
    user_uuid = socket.assigns.current_user_uuid

    Presence.track(socket, user_uuid, %{online_at: inspect(System.system_time(:second))})

    {:noreply, socket}
  end

  def handle_info({:game_state_updated, game}, socket) do
    Logger.info("Game state updated for room #{socket.topic}: #{inspect(game)}")

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

    case GameSession.start_game_session(room_id)  do
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
    current_user_uuid = socket.assigns.current_user_uuid

    with true <- GameSession.owner?(room_id, current_user_uuid),
         {:ok, game} <- GameSession.start_playback(room_id) do
      broadcast(socket, "state_updated", game)
      {:reply, :ok, socket}
    else
      other ->
        Logger.warning("Start playback failed with: #{inspect(other)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("pause_playback", _payload, socket) do
    @room_prefix <> room_id = socket.topic
    current_user_uuid = socket.assigns.current_user_uuid

    with true <- GameSession.owner?(room_id, current_user_uuid),
         {:ok, game} <- GameSession.pause_playback(room_id) do
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
  def handle_in("get_spotify_token", _payload, socket) do
    user_uuid = socket.assigns.current_user_uuid

    case Songy.Providers.lookup(:providers, user_uuid) do
      {:ok, {:spotify, %{access_token: token}}} when not is_nil(token) ->
        {:reply, {:ok, %{token: token}}, socket}

      {:ok, {_other_provider, _data}} ->
        {:reply, {:error, %{reason: "invalid_credentials"}}, socket}

      {:error, _reason} ->
        {:reply, {:error, %{reason: "invalid_credentials"}}, socket}
    end
  end

  @impl true
  def handle_in("get_current_user", _payload, socket) do
    user_uuid = socket.assigns.current_user_uuid
    user = Songy.Core.User.get_user(user_uuid)
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
    current_user_uuid = socket.assigns.current_user_uuid

    case GameSession.make_assumption(room_id, current_user_uuid, position) do
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
    user_uuid = socket.assigns.current_user_uuid

    case GameSession.reorder_timeline(room_id, user_uuid, position) do
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
