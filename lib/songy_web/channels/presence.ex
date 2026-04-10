defmodule SongyWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :songy,
    pubsub_server: Songy.PubSub

  @presence_prefix "presence:"
  @room_prefix "room:"

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas(@room_prefix <> _room_id = topic, %{joins: joins, leaves: leaves}, presences, state) do
    # Emit participant join events
    for {user_id, _} <- joins do
      Phoenix.PubSub.local_broadcast(
        Songy.PubSub,
        @presence_prefix <> topic,
        {:participant_joined, user_id}
      )
    end

    # Emit participant leave events
    for {user_id, _} <- leaves, not present?(presences, user_id) do
      Phoenix.PubSub.local_broadcast(
        Songy.PubSub,
        @presence_prefix <> topic,
        {:participant_left, user_id}
      )
    end

    {:ok, state}
  end

  defp present?(presences, user_id) do
    case Map.get(presences, user_id) do
      %{metas: [_ | _]} -> true
      _ -> false
    end
  end

  def subscribe(room_id),
    do:
      Phoenix.PubSub.subscribe(
        Songy.PubSub,
        @presence_prefix <> @room_prefix <> room_id
      )
end
