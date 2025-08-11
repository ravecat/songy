<script lang="ts">
  import { getChannelContext } from "@shared/context/channel";
  import TurnWaiting from "@components/TurnWaiting.svelte";
  import TurnPlaying from "@components/TurnPlaying.svelte";
  import TurnChallenging from "@components/TurnChallenging.svelte";
  import TurnResults from "@components/TurnResults.svelte";

  const { state } = $derived.by(getChannelContext);
  const turnPhase = $derived(state?.turn?.phase);
</script>

{#if turnPhase === "turn_waiting"}
  <TurnWaiting />
{:else if turnPhase === "turn_playing"}
  <TurnPlaying />
{:else if turnPhase === "turn_challenging"}
  <TurnChallenging />
{:else if turnPhase === "turn_results"}
  <TurnResults />
{:else}
  <TurnPlaying />
{/if}
