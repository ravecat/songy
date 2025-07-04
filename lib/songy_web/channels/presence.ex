defmodule SongyWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :songy,
    pubsub_server: Songy.PubSub

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas("room:" <> _room_id = topic, %{joins: joins, leaves: leaves}, _, state) do
    # Emit participant join events
    for {user_uuid, _} <- joins do
      Phoenix.PubSub.local_broadcast(
        Songy.PubSub,
        topic,
        {:participant_joined, user_uuid}
      )
    end

    # Emit participant leave events
    for {user_uuid, _} <- leaves do
      Phoenix.PubSub.local_broadcast(
        Songy.PubSub,
        topic,
        {:participant_left, user_uuid}
      )
    end

    {:ok, state}
  end
end
