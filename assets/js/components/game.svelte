<script lang="ts">
  import { getGameContext } from "~/contexts/game";
  import TurnWaiting from "~components/turn_waiting.svelte";
  import Timeline from "~components/timeline.svelte";
  import TurnResults from "~components/turn_results.svelte";
  import Lobby from "~components/lobby.svelte";

  const session = $derived.by(getGameContext);
  const game = $derived(session.snapshot?.game ?? null);
  const phase = $derived(game?.turn?.phase);
  const status = $derived(game?.status);
</script>

{#if phase === "waiting"}
  <TurnWaiting />
{:else if phase === "ready" || phase === "challenging"}
  <Timeline />
{:else if phase === "results"}
  <TurnResults />
{:else if status === "waiting"}
  <Lobby />
{/if}
