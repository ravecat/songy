<script lang="ts">
  import ActiveTimeline from "~components/ActiveTimeline.svelte";
  import CurrentTrack from "~components/CurrentTrack.svelte";
</script>

<div class="turn-layout">
  <div class="turn-timeline">
    <ActiveTimeline />
  </div>
  <div class="turn-current">
    <CurrentTrack />
  </div>
</div>

<style>
  .turn-layout {
    display: flex;
    flex-direction: column;
    flex: 1;
    min-height: 0;
  }

  .turn-timeline {
    display: flex;
    flex: 1;
    min-height: 0;
  }

  .turn-timeline :global(.timeline) {
    flex: 1;
    min-height: 0;
  }

  .turn-current {
    flex-shrink: 0;
  }
</style>
