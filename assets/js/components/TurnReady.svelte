<script lang="ts">
  import CurrentTrack from "~components/CurrentTrack.svelte";
  import ActiveTimeline from "~components/ActiveTimeline.svelte";
</script>

<div class="flex flex-col flex-1 min-h-0">
  <div class="flex flex-1 min-h-0">
    <ActiveTimeline />
  </div>
  <div class="flex-shrink-0">
    <CurrentTrack />
  </div>
</div>
