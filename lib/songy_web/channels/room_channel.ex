defmodule SongyWeb.RoomChannel do
  use SongyWeb, :channel

  alias SongyWeb.Presence
  alias Songy.Boundary.GameSession

  require Logger

  @impl true
  def join("room:" <> _room_id, _payload, socket) do
    send(self(), :after_join)

    {:ok, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.current_user_uuid, %{
        online_at: inspect(System.system_time(:second))
      })

    {:noreply, socket}
  end

  @impl true
  def handle_info({:participant_joined, user_uuid}, socket) do
    "room:" <> room_id = socket.topic

    case GameSession.add_participant(room_id, user_uuid) do
      {:ok, game} ->
        broadcast(socket, "update_state", game)
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:participant_left, user_uuid}, socket) do
    "room:" <> room_id = socket.topic

    case GameSession.remove_participant(room_id, user_uuid) do
      {:ok, game} ->
        broadcast(socket, "update_state", game)
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("start_game", _payload, socket) do
    "room:" <> room_id = socket.topic

    case GameSession.start_game_session(room_id) do
      {:ok, game} ->
        broadcast(socket, "update_state", game)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("register_device", _payload, socket) do
    {:noreply, socket}
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
