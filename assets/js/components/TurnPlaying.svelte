<script lang="ts">
  import Participants from "@components/Participants.svelte";
  import Player from "@components/Player.svelte";
  import CurrentTrack from "@components/CurrentTrack.svelte";
  import ParticipantTimeline from "@components/ParticipantTimeline.svelte";
</script>

<Participants />
<div class="flex items-center justify-center gap-4 py-4">
  <CurrentTrack />
  <ParticipantTimeline />
</div>
<Player />
