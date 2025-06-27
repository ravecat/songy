defmodule SongyWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :songy,
    pubsub_server: Songy.PubSub

  alias Songy.Boundary.GameSession

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas("room:" <> room_id = topic, %{joins: joins, leaves: leaves}, _, state) do
    for {user_uuid, _} <- joins do
      case GameSession.add_participant(room_id, user_uuid) do
        {:ok, game} ->
          Phoenix.PubSub.local_broadcast(
            Songy.PubSub,
            topic,
            {:game_state, game}
          )

        {:error, _reason} ->
          :ok
      end
    end

    for {user_uuid, _} <- leaves do
      case GameSession.remove_participant(room_id, user_uuid) do
        {:ok, game} ->
          Phoenix.PubSub.local_broadcast(
            Songy.PubSub,
            topic,
            {:game_state, game}
          )

        {:error, _reason} ->
          :ok
      end
    end

    {:ok, state}
  end
end
