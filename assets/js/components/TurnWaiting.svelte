<script lang="ts">
  import { getGameContext } from "~components/GameContext.svelte";

  const { state, channel } = $derived.by(getGameContext);

  const currentPlayer = $derived.by(() => {
    const currentPlayerUuid =
      state?.turn?.queue?.[state?.turn?.current_player_index];

    return state?.participants?.find(({ uuid }) => uuid === currentPlayerUuid)!;
  });

  const handleReady = () => {
    channel.push("next_phase", {});
  };
</script>

<div class="turn-waiting-screen">
  <div class="player-info">
    <img
      src={currentPlayer.avatar_url}
      alt={currentPlayer.name}
      class="player-avatar"
    />
    <h2>{currentPlayer.name} turn</h2>
  </div>
  <button class="btn btn-primary w-full" onclick={handleReady}>Ready?</button>
</div>

<style>
  .turn-waiting-screen {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    min-height: 60vh;
    text-align: center;
    padding: 2rem;
  }

  .player-info {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    margin-bottom: 2rem;
  }

  .player-avatar {
    width: 4rem;
    height: 4rem;
    border-radius: 50%;
    object-fit: cover;
    border: 3px solid #3b82f6;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  }

  h2 {
    margin: 0;
    color: #333;
    font-size: 1.5rem;
  }

  .btn {
    max-width: 400px;
  }
</style>
