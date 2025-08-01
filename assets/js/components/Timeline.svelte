<script>
  import { getScopeContext } from "@shared/context/scope";
  import { getChannelContext } from "@shared/context/channel.js";
  import TrackCard from "@components/TrackCard.svelte";
  import { dndzone } from "svelte-dnd-action";
  import { flip } from "svelte/animate";

  const { state } = $derived.by(getChannelContext);
  const { user } = $derived.by(getScopeContext);

  let participantTimeline = $derived.by(() => {
    const timeline = state?.timelines?.[user?.uuid] || [];

    return timeline.map((track, index) => ({
      id: index,
      track,
    }));
  });

  const flipDurationMs = 150;

  function handleDndConsider(e) {
    participantTimeline = e.detail.items;
  }

  function handleDndFinalize({ detail: { items, info } }) {
    participantTimeline = items;

    const draggedId = info.id;
    const newPosition = items.findIndex((item) => item.id === draggedId);

    console.log(`Element ${draggedId} moved to position ${newPosition}`);
  }
</script>

<div
  class="timeline"
  use:dndzone={{
    items: participantTimeline,
    flipDurationMs,
    dropTargetStyle: {},
  }}
  onconsider={handleDndConsider}
  onfinalize={handleDndFinalize}
>
  {#each participantTimeline as item (item.id)}
    <div animate:flip={{ duration: flipDurationMs }}>
      <TrackCard track={item.track} />
    </div>
  {/each}
</div>

<style>
  .timeline {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 1rem;
    padding: 1rem;
  }
</style>
