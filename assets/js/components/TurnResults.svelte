<script lang="ts">
  import Participants from "~components/Participants.svelte";
  import ActiveTimeline from "~components/ActiveTimeline.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";
  import { getGameContext } from "~components/GameContext.svelte";

  const { channel, state } = $derived.by(getGameContext);
  const status = $derived(state?.status);

  const handleNextTurn = () => {
    channel.push(PUSH_EVENT.NEXT_PHASE, {});
  };
</script>

<Participants />
<ActiveTimeline />
{#if status === "finished"}
  <p>Game Over</p>
{/if}
{#if status !== "finished"}
  <button class="btn" onclick={handleNextTurn}>Next Turn</button>
{/if}
