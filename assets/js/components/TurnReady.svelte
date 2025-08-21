<script lang="ts">
  import Participants from "~components/Participants.svelte";
  import Player from "~components/Player.svelte";
  import CurrentTrack from "~components/CurrentTrack.svelte";
  import ActiveTimeline from "~components/ActiveTimeline.svelte";
  import { getGameContext } from "~components/GameContext.svelte";
  import { getScopeContext } from "~components/Scope.svelte";

  const { state } = $derived.by(getGameContext);
  const { user: currentPlayer } = $derived.by(getScopeContext);
  const activePlayerUuid = $derived.by(() => {
    return state?.turn?.queue?.[state?.turn?.cursor];
  });
  const activePlayer = $derived.by(() => {
    return state?.participants?.find(({ uuid }) => uuid === activePlayerUuid);
  });

  const isChallenger = $derived.by(() => {
    return activePlayer?.uuid !== currentPlayer?.uuid;
  });
</script>

{#if isChallenger}
  <Participants />
  <ActiveTimeline />
{:else}
  <Participants />
  <ActiveTimeline />
  <CurrentTrack />
  <Player />
{/if}
