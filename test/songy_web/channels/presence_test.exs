defmodule SongyWeb.PresenceTest do
  use ExUnit.Case, async: true

  alias SongyWeb.Presence

  describe "handle_metas/4" do
    test "broadcasts participant_left only after the last meta leaves" do
      room_id = "presence-room-still-online"
      topic = "room:#{room_id}"
      Phoenix.PubSub.subscribe(Songy.PubSub, "presence:#{topic}")

      assert {:ok, %{}} =
               Presence.handle_metas(
                 topic,
                 %{
                   joins: %{},
                   leaves: %{"user-1" => %{metas: [%{phx_ref: "ref-1"}]}}
                 },
                 %{"user-1" => %{metas: [%{phx_ref: "ref-2"}]}},
                 %{}
               )

      refute_receive {:participant_left, "user-1"}
    end

    test "broadcasts participant_left when no metas remain" do
      room_id = "presence-room-offline"
      topic = "room:#{room_id}"
      Phoenix.PubSub.subscribe(Songy.PubSub, "presence:#{topic}")

      assert {:ok, %{}} =
               Presence.handle_metas(
                 topic,
                 %{
                   joins: %{},
                   leaves: %{"user-1" => %{metas: [%{phx_ref: "ref-1"}]}}
                 },
                 %{},
                 %{}
               )

      assert_receive {:participant_left, "user-1"}
    end
  end
end
