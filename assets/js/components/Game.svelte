<script lang="ts">
  import { getGameContext } from "~components/GameChannel.svelte";
  import { TURN_PHASE } from "~shared/types/turn";
  import { GAME_STATUS } from "~shared/types/game";
  import TurnWaiting from "~components/TurnWaiting.svelte";
  import TurnChallenging from "~components/TurnChallenging.svelte";
  import TurnResults from "~components/TurnResults.svelte";
  import TurnReady from "~components/TurnReady.svelte";

  const { game } = $derived.by(getGameContext);
  const turnPhase = $derived(game?.turn?.phase);
  const gameStatus = $derived(game?.status);
  const hasMoreThanOnePlayer = $derived((game?.participants?.length ?? 0) > 1);
</script>

{#if turnPhase === TURN_PHASE.WAITING}
  <TurnWaiting />
{:else if turnPhase === TURN_PHASE.READY}
  <TurnReady />
{:else if turnPhase === TURN_PHASE.CHALLENGING}
  <TurnChallenging />
{:else if turnPhase === TURN_PHASE.RESULTS}
  <TurnResults />
{:else if gameStatus === GAME_STATUS.WAITING && !hasMoreThanOnePlayer}
  waiting for players...
{/if}
