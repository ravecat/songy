<script lang="ts">
  import { getScopeContext } from "~shared/context/scope";
  import { getChannelContext } from "~shared/context/channel";
  import TrackCard from "~components/TrackCard.svelte";
  import Timeline from "~components/Timeline.svelte";
  import { type DndEvent } from "svelte-dnd-action";

  const { state, channel } = $derived.by(getChannelContext);
  const { user } = $derived.by(getScopeContext);
  const turnTrack = $derived(state?.turn?.track);

  let timeline = $derived.by(() => {
    const timeline = state?.timelines?.[user?.uuid] || [];

    return timeline.map((track) => ({
      id: track.id,
      track,
      current: false,
    }));
  });

  type TimelineItem = (typeof timeline)[number];

  function handleFinalize({
    detail: { items, info },
  }: CustomEvent<DndEvent<TimelineItem>>) {
    timeline = items;

    const draggedId = info.id;
    const newPosition = items.findIndex(({ id }) => id === draggedId);

    const isFromTurnTrack = turnTrack?.id === draggedId;

    if (isFromTurnTrack) {
      channel?.push("extend_timeline", {
        position: newPosition,
      });
    } else {
      channel?.push("reorder_timeline", {
        track_id: draggedId,
        position: newPosition,
      });
    }
  }
</script>

<Timeline items={timeline} onfinalize={handleFinalize}>
  {#snippet children(item)}
    <TrackCard revealed={!item.current} track={item.track} />
  {/snippet}
</Timeline>
