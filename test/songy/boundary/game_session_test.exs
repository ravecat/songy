defmodule Songy.Boundary.GameSessionTest do
  use ExUnit.Case, async: true
  use Repatch.ExUnit
  use AssertEventually

  alias Songy.Boundary.GameSession
  alias Songy.Core.Provider

  describe "create_game_session/2" do
    test "starts new game session process with owner and provider" do
      owner_uuid = "owner123"
      provider = Provider.new(:spotify)
      assert {:ok, game} = GameSession.create_game_session(owner_uuid, provider)

      pid =
        case Registry.lookup(Songy.Registry, game.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      assert Process.alive?(pid)
      assert game.uuid != nil
      assert game.participants == []
      assert game.owner_uuid == owner_uuid
      assert %Provider{id: :spotify} = game.provider
    end

    test "multiple different games can be started with different owners and providers" do
      provider1 = Provider.new(:spotify)
      provider2 = Provider.new(:spotify)

      assert {:ok, game1} = GameSession.create_game_session("owner1", provider1)
      assert {:ok, game2} = GameSession.create_game_session("owner2", provider2)

      pid1 =
        case Registry.lookup(Songy.Registry, game1.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      pid2 =
        case Registry.lookup(Songy.Registry, game2.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      assert Process.alive?(pid1)
      assert Process.alive?(pid2)
      assert pid1 != pid2
      assert game1.uuid != game2.uuid
      assert game1.owner_uuid == "owner1"
      assert game2.owner_uuid == "owner2"
      assert %Provider{id: :spotify} = game1.provider
      assert %Provider{id: :spotify} = game2.provider
    end
  end

  describe "add_participant/2" do
    setup do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)

      pid =
        case Registry.lookup(Songy.Registry, game.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      %{game: game, pid: pid}
    end

    test "adds participant to game session", %{game: game} do
      participant_uuid = "user123"

      assert {:ok, updated_game} = GameSession.add_participant(game.uuid, participant_uuid)
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == participant_uuid
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = GameSession.add_participant("nonexistent", "user123")
    end

    test "returns error when game is full", %{game: _game} do
      # Create a game with default max participants (8)
      provider = Provider.new(:spotify)
      {:ok, small_game} = GameSession.create_game_session("owner123", provider)

      # Add participants up to max capacity
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user1")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user2")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user3")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user4")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user5")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user6")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user7")
      assert {:ok, _updated_game} = GameSession.add_participant(small_game.uuid, "user8")

      # Try to add 9th participant (should fail since max is 8)
      assert {:error, :game_full} = GameSession.add_participant(small_game.uuid, "user9")
    end

    test "returns error when participant already joined", %{game: game} do
      participant_uuid = "user123"

      assert {:ok, _updated_game} = GameSession.add_participant(game.uuid, participant_uuid)

      assert {:error, :user_already_joined} =
               GameSession.add_participant(game.uuid, participant_uuid)
    end

    test "handles concurrent participant additions", %{game: _game} do
      provider = Provider.new(:spotify)
      {:ok, limited_game} = GameSession.create_game_session("owner123", provider)

      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            GameSession.add_participant(limited_game.uuid, "user#{i}")
          end)
        end

      results = Task.await_many(tasks)
      # Since we're using a normal game (max 6), all 5 should succeed
      successful = Enum.count(results, &match?({:ok, _}, &1))
      failed = Enum.count(results, &match?({:error, _}, &1))

      assert successful == 5
      assert failed == 0
    end
  end

  describe "end_game_session/1" do
    test "terminates game session process" do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)

      assert :ok = GameSession.end_game_session(game.uuid)
      assert_eventually([] = Registry.lookup(Songy.Registry, game.uuid))
    end

    test "handles termination of non-existent session" do
      assert :ok = GameSession.end_game_session("nonexistent")
    end
  end

  describe "remove_participant/2" do
    setup do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)

      pid =
        case Registry.lookup(Songy.Registry, game.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      %{game: game, pid: pid}
    end

    test "removes participant from game session", %{game: game} do
      participant_uuid = "user123"

      # Add participant first
      assert {:ok, game_with_participant} =
               GameSession.add_participant(game.uuid, participant_uuid)

      assert length(game_with_participant.participants) == 1

      # Remove participant
      assert {:ok, updated_game} = GameSession.remove_participant(game.uuid, participant_uuid)
      assert length(updated_game.participants) == 0
    end

    test "returns error when removing non-existent participant", %{game: game} do
      assert {:error, :user_not_found} = GameSession.remove_participant(game.uuid, "nonexistent")
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = GameSession.remove_participant("nonexistent", "user123")
    end
  end

  describe "lookup_game_session/1" do
    setup do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)

      pid =
        case Registry.lookup(Songy.Registry, game.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      %{game: game, pid: pid}
    end

    test "returns current game state", %{game: game} do
      assert {:ok, returned_game} = GameSession.lookup_game_session(game.uuid)
      assert returned_game.uuid == game.uuid
      assert returned_game.participants == []
      assert returned_game.status == :waiting
    end

    test "returns updated game state after participant addition", %{game: game} do
      participant_uuid = "user123"
      {:ok, _} = GameSession.add_participant(game.uuid, participant_uuid)

      assert {:ok, updated_game} = GameSession.lookup_game_session(game.uuid)
      assert length(updated_game.participants) == 1
      assert hd(updated_game.participants).uuid == participant_uuid
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = GameSession.lookup_game_session("nonexistent")
    end
  end

  describe "start_game_session/1" do
    setup do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)

      pid =
        case Registry.lookup(Songy.Registry, game.uuid) do
          [{pid, nil}] -> pid
          [] -> flunk("Process not found in registry")
        end

      %{game: game, pid: pid}
    end

    test "starts the game by changing status to in_progress", %{game: game} do
      # Verify initial status is :waiting
      assert {:ok, initial_game} = GameSession.lookup_game_session(game.uuid)
      assert initial_game.status == :waiting

      # Start the game
      assert {:ok, updated_game} = GameSession.start_game_session(game.uuid)
      assert updated_game.status == :in_progress

      # Verify the game state was persisted
      assert {:ok, persisted_game} = GameSession.lookup_game_session(game.uuid)
      assert persisted_game.status == :in_progress
    end

    test "returns error when game is already started", %{game: game} do
      # Start the game first
      assert {:ok, _} = GameSession.start_game_session(game.uuid)

      # Try to start again
      assert {:error, :game_already_started} = GameSession.start_game_session(game.uuid)
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = GameSession.start_game_session("nonexistent")
    end
  end

  describe "owner?/2" do
    setup do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)
      %{game: game}
    end

    test "returns true when user is owner", %{game: game} do
      assert GameSession.owner?(game.uuid, "owner123") == true
    end

    test "returns false when user is not owner", %{game: game} do
      assert GameSession.owner?(game.uuid, "other456") == false
    end

    test "returns false for non-existent session" do
      assert GameSession.owner?("nonexistent", "user123") == false
    end
  end

  describe "update_provider/2 spotify" do
    setup do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)
      %{game: game}
    end

    test "updates provider successfully", %{game: game} do
      provider_data = %{device_id: "test-device-123"}

      assert {:ok, updated_game} = GameSession.update_provider(game.uuid, provider_data)
      assert updated_game.provider.meta.device_id == "test-device-123"
    end

    test "returns error for non-existent session" do
      provider_data = %{device_id: "test-device-123"}

      assert {:error, :not_found} = GameSession.update_provider("nonexistent", provider_data)
    end
  end

  describe "start_playback/1" do
    test "starts playback when game is in progress" do
      # Create and start game session
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)
      {:ok, _} = GameSession.start_game_session(game.uuid)

      # Verify initial playback state
      {:ok, initial_game} = GameSession.lookup_game_session(game.uuid)
      assert initial_game.player.is_playback == false

      # Start playback
      assert {:ok, updated_game} = GameSession.start_playback(game.uuid)
      assert updated_game.player.is_playback == true

      # Verify state persisted
      {:ok, persisted_game} = GameSession.lookup_game_session(game.uuid)
      assert persisted_game.player.is_playback == true

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end

    test "returns error when game is in waiting status" do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)

      # Don't start the game, leave it in :waiting status
      assert {:error, :game_not_in_progress} = GameSession.start_playback(game.uuid)

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = GameSession.start_playback("nonexistent-uuid")
    end

    test "idempotent when playback already started" do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)
      {:ok, _} = GameSession.start_game_session(game.uuid)

      # Start playback twice
      assert {:ok, first_result} = GameSession.start_playback(game.uuid)
      assert {:ok, second_result} = GameSession.start_playback(game.uuid)

      # Both should show playback as true
      assert first_result.player.is_playback == true
      assert second_result.player.is_playback == true

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end
  end

  describe "stop_playback/1" do
    test "stops playback when game is in progress" do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)
      {:ok, _} = GameSession.start_game_session(game.uuid)
      {:ok, _} = GameSession.start_playback(game.uuid)

      # Verify playback is started
      {:ok, playing_game} = GameSession.lookup_game_session(game.uuid)
      assert playing_game.player.is_playback == true

      # Stop playback
      assert {:ok, updated_game} = GameSession.stop_playback(game.uuid)
      assert updated_game.player.is_playback == false

      # Verify state persisted
      {:ok, persisted_game} = GameSession.lookup_game_session(game.uuid)
      assert persisted_game.player.is_playback == false

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end

    test "returns error when game is in waiting status" do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)

      # Don't start the game, leave it in :waiting status
      assert {:error, :game_not_in_progress} = GameSession.stop_playback(game.uuid)

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end

    test "returns error for non-existent session" do
      assert {:error, :not_found} = GameSession.stop_playback("nonexistent-uuid")
    end

    test "idempotent when playback already stopped" do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)
      {:ok, _} = GameSession.start_game_session(game.uuid)

      # Verify playback is initially stopped
      {:ok, initial_game} = GameSession.lookup_game_session(game.uuid)
      assert initial_game.player.is_playback == false

      # Stop playback (should be idempotent)
      assert {:ok, first_result} = GameSession.stop_playback(game.uuid)
      assert {:ok, second_result} = GameSession.stop_playback(game.uuid)

      # Both should show playback as false
      assert first_result.player.is_playback == false
      assert second_result.player.is_playback == false

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end

    test "start then stop playback sequence" do
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)
      {:ok, _} = GameSession.start_game_session(game.uuid)

      # Initial state: not playing
      {:ok, initial_game} = GameSession.lookup_game_session(game.uuid)
      assert initial_game.player.is_playback == false

      # Start playback
      {:ok, playing_game} = GameSession.start_playback(game.uuid)
      assert playing_game.player.is_playback == true

      # Stop playback
      {:ok, stopped_game} = GameSession.stop_playback(game.uuid)
      assert stopped_game.player.is_playback == false

      # Verify final state persisted
      {:ok, final_game} = GameSession.lookup_game_session(game.uuid)
      assert final_game.player.is_playback == false

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end
  end
end
