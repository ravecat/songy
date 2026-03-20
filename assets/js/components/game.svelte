<script lang="ts">
  import { getGameContext } from "~components/game_channel.svelte";
  import { TURN_PHASE } from "~shared/types/turn";
  import { GAME_STATUS } from "~shared/types/game";
  import TurnWaiting from "~components/turn_waiting.svelte";
  import Timeline from "~components/timeline.svelte";
  import TurnResults from "~components/turn_results.svelte";
  import Lobby from "~components/lobby.svelte";

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
  <Lobby />
{/if}
