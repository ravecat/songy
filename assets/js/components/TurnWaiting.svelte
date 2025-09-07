<script lang="ts">
  import { getGameContext } from "~components/GameContext.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";

  const { state, channel } = $derived.by(getGameContext);
  const { user: currentPlayer } = $derived.by(getScopeContext);

  const activePlayer = $derived.by(() => {
    const activePlayerUuid = state?.turn?.queue?.[state?.turn?.cursor];

    return state?.participants?.find(({ uuid }) => uuid === activePlayerUuid)!;
  });

  const isCurrentPlayerActive = $derived.by(() => {
    return currentPlayer?.uuid === activePlayer?.uuid;
  });

  const handleReady = () => {
    channel.push(PUSH_EVENT.NEXT_PHASE, {});
  };
</script>

<div class="turn-waiting-screen">
  <div class="player-info">
    <div class="avatar">
      <div
        class="ring-primary ring-offset-base-100 w-16 rounded-full ring-2 ring-offset-2"
      >
        <img src={activePlayer.avatar_url} alt={activePlayer.name} />
      </div>
    </div>
    <h2 class="mb-0">
      {isCurrentPlayerActive ? "It's your turn" : `${activePlayer.name} turn`}
    </h2>
    {#if isCurrentPlayerActive}
      <button class="btn btn-primary w-full" onclick={handleReady}>Ready?</button>
    {/if}
  </div>
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
  }

  h2 {
    color: #333;
    font-size: 1.5rem;
  }
</style>
