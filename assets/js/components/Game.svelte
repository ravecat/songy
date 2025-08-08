<script>
  import { getChannelContext } from "@shared/context/channel.js";
  import Participants from "@components/Participants.svelte";
  import PlayerButton from "@components/PlayerButton.svelte";
  import CurrentTrack from "@components/CurrentTrack.svelte";
  import ParticipantTimeline from "@components/ParticipantTimeline.svelte";
</script>

<div class="mx-auto min-w-[24rem] max-w-[36rem] space-y-2">
  <Participants />
  <PlayerButton />
  <div class="flex items-center justify-center gap-4 py-4">
    <CurrentTrack />
    <ParticipantTimeline />
  </div>
</div>
