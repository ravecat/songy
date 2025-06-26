defmodule SongyWeb.RoomChannel do
  use SongyWeb, :channel

  alias SongyWeb.Presence

  @impl true
  def join("room:" <> room_hash, _payload, socket) do
    send(self(), :after_join)

    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:room_hash, room_hash)
      |> assign(:user, user)

    {:ok, %{current_user: %{uuid: user.uuid, name: user.name, avatar_url: user.avatar_url}},
     socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    user = socket.assigns.user

    {:ok, _} =
      Presence.track(socket, user.uuid, %{
        name: user.name,
        avatar_url: user.avatar_url,
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  @impl true
  def handle_in(event, _payload, socket) do
    {:reply, {:error, %{reason: "unknown_event", event: event}}, socket}
  end
end
