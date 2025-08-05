<script>
  import { getScopeContext } from "@shared/context/scope";
  import { getChannelContext } from "@shared/context/channel.js";
  import TrackCard from "@components/TrackCard.svelte";
  import Timeline from "@components/Timeline.svelte";

  const { state } = $derived.by(getChannelContext);
  const { user } = $derived.by(getScopeContext);

  let timeline = $derived.by(() => {
    const timeline = state?.timelines?.[user?.uuid] || [];

    return timeline.map((track) => ({
      id: track.title,
      track,
    }));
  });

  function handleFinalize({ detail: { items, info } }) {
    timeline = items;

    const draggedId = info.id;
    const newPosition = items.findIndex((item) => item.id === draggedId);

    console.log(`Element ${draggedId} moved to position ${newPosition}`);
  }
</script>

<Timeline items={timeline} onFinalize={handleFinalize}>
  {#snippet children(item)}
    <TrackCard revealed={!item.current} track={item.track} />
  {/snippet}
</Timeline>
