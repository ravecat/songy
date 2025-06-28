defmodule SongyWeb.RoomChannel do
  use SongyWeb, :channel

  alias SongyWeb.Presence
  alias Songy.Boundary.GameSession

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
  def handle_info({:game_state, game}, socket) do
    broadcast(socket, "game_state", game)

    {:noreply, socket}
  end

  @impl true
  def handle_in("start_game", _payload, socket) do
    dbg("Starting game in room: #{socket.topic}")
    "room:" <> room_id = socket.topic

    case GameSession.start_game(room_id) do
      {:ok, game} ->
        broadcast(socket, "game_state", game)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in(event, _payload, socket) do
    {:reply, {:error, %{reason: "unknown_event", event: event}}, socket}
  end
end
