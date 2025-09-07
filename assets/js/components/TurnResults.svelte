<script lang="ts">
  import Participants from "~components/Participants.svelte";
  import ActiveTimeline from "~components/ActiveTimeline.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";
  import { getGameContext } from "~components/GameContext.svelte";
  import { inertia } from "@inertiajs/svelte";
  import { GAME_STATUS } from "~shared/types/game";

  const { channel, state } = $derived.by(getGameContext);
  const status = $derived(state?.status);

  const handleNextTurn = () => {
    channel.push(PUSH_EVENT.NEXT_PHASE, {});
  };
</script>

<Participants />
<ActiveTimeline />
{#if status === GAME_STATUS.FINISHED}
  <form use:inertia={{ href: "/create", method: "post" }}>
    <button type="submit" class="btn">Play again</button>
  </form>
{:else}
  <button class="btn" onclick={handleNextTurn}>Next Turn</button>
{/if}
