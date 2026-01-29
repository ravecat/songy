<script lang="ts">
  import { getGameContext } from "~components/GameChannel.svelte";
  import { TURN_PHASE } from "~shared/types/turn";
  import { GAME_STATUS } from "~shared/types/game";
  import TurnWaiting from "~components/TurnWaiting.svelte";
  import Timeline from "~components/Timeline.svelte";
  import TurnResults from "~components/TurnResults.svelte";

  const { game } = $derived.by(getGameContext);
  const phase = $derived(game?.turn?.phase);
  const status = $derived(game?.status);
</script>

{#if phase === TURN_PHASE.WAITING}
  <TurnWaiting />
{:else if phase === TURN_PHASE.READY || phase === TURN_PHASE.CHALLENGING}
  <Timeline />
{:else if phase === TURN_PHASE.RESULTS}
  <TurnResults />
{:else if status === GAME_STATUS.WAITING}
  <div class="game-waiting">waiting for players...</div>
{/if}

<style>
  .game-waiting {
    display: flex;
    align-items: center;
    justify-content: center;
  }
</style>
