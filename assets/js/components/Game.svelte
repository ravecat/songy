<script>
  import { untrack } from "svelte";
  import { modals } from "svelte-modals";
  import { getChannelContext } from "@shared/context/channel.js";
  import Participants from "@components/Participants.svelte";
  import Player from "@components/Player.svelte";
  import CurrentTrack from "@components/CurrentTrack.svelte";
  import ParticipantTimeline from "@components/ParticipantTimeline.svelte";
  import TurnWaitingModal from "@components/TurnWaitingModal.svelte";

  const { state } = $derived(getChannelContext());

  $effect(() => {
    if (state?.turn?.phase === "turn_waiting") {
      untrack(() => {
        modals.open(TurnWaitingModal);
      });
    }
  });
</script>

<Participants />
<div class="flex items-center justify-center gap-4 py-4">
  <CurrentTrack />
  <ParticipantTimeline />
</div>
<Player />
