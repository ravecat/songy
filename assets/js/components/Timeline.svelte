<script>
  import { getScopeContext } from "@shared/context/scope";
  import { getChannelContext } from "@shared/context/channel.js";
  import TrackCard from "@components/TrackCard.svelte";

  const { state } = $derived.by(getChannelContext);
  const { user } = $derived.by(getScopeContext);

  let userTimeline = $derived(state?.timelines?.[user?.uuid] || []);
</script>

<div class="timeline">
  {#each userTimeline as track (track.title + track.artist + track.year)}
    <TrackCard {track} />
  {/each}
</div>

<style>
  .timeline {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 1rem;
  }
</style>
