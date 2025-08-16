<script lang="ts">
  import { getGameContext } from "~components/GameContext.svelte";
  import { TURN_PHASE } from "~shared/types/turn";
  import TurnWaiting from "~components/TurnWaiting.svelte";
  import TurnPlaying from "~components/TurnPlaying.svelte";
  import TurnChallenging from "~components/TurnChallenging.svelte";
  import TurnResults from "~components/TurnResults.svelte";

  const { state } = $derived.by(getGameContext);
  const turnPhase = $derived(state?.turn?.phase);
</script>

{#if turnPhase === TURN_PHASE.WAITING}
  <TurnWaiting />
{:else if turnPhase === TURN_PHASE.CHALLENGING}
  <TurnChallenging />
{:else if turnPhase === TURN_PHASE.RESULTS}
  <TurnResults />
{:else}
  <TurnPlaying />
{/if}
