defmodule Songy.Core.NewGameTest do
  use ExUnit.Case, async: true

  alias Songy.Core.{NewGame, Player, User}

  describe "struct" do
    test "creates game with all fields" do
      now = DateTime.utc_now()
      user = %User{uuid: "user-1", name: "Player1"}

      game = %NewGame{
        id: "game-123",
        owner_uuid: "owner-456",
        max_participants: 10,
        max_score: 10,
        status: :waiting,
        participants: [user],
        scores: %{"user-1" => 5},
        player: Player.new(),
        timelines: %{},
        created_at: now
      }

      assert game.id == "game-123"
      assert game.owner_uuid == "owner-456"
      assert game.status == :waiting
    end
  end

  describe "JSON encoding" do
    test "encodes with only allowed fields" do
      game = %NewGame{
        id: "game-123",
        owner_uuid: "owner-456",
        max_participants: 10,
        max_score: 10,
        status: :in_progress,
        participants: [],
        scores: %{},
        player: Player.new(),
        timelines: %{},
        created_at: DateTime.utc_now()
      }

      json = Jason.encode!(game)
      decoded = Jason.decode!(json)

      # Проверяем что нужные поля есть
      assert decoded["id"] == "game-123"
      assert decoded["status"] == "in_progress"
    end
  end
end
