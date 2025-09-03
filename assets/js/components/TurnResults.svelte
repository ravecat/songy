<script lang="ts">
  import Participants from "~components/Participants.svelte";
  import ActiveTimeline from "~components/ActiveTimeline.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";
  import { getGameContext } from "~components/GameContext.svelte";

  const { channel } = $derived.by(getGameContext);

  const handleNextTurn = () => {
    channel.push(PUSH_EVENT.NEXT_PHASE, {});
  };
</script>

<Participants />
<ActiveTimeline />
<button class="btn" onclick={handleNextTurn}>Next Turn</button>
