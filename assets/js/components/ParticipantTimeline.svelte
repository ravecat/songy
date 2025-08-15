<script lang="ts">
  import { getScopeContext } from "~shared/context/scope";
  import { getGameContext } from "~components/GameContext.svelte";
  import TrackCard from "~components/TrackCard.svelte";
  import Timeline from "~components/Timeline.svelte";
  import { type DndEvent, TRIGGERS } from "svelte-dnd-action";
  import { dragOriginZone } from "~shared/stores/dragOrigin";
  import { get } from "svelte/store";

  const { state, channel } = $derived.by(getGameContext);
  const { user } = $derived.by(getScopeContext);
  const currentTrack = $derived(state?.turn?.track);
  const zoneId = $derived(`participant-timeline-${user.uuid}`);

  let timeline = $derived.by(() => {
    const timeline = state?.timelines?.[user.uuid] || [];

    return timeline.map((track) => ({
      id: track.id,
      track,
      current: track.id === currentTrack?.id,
    }));
  });

  type TimelineItem = (typeof timeline)[number];

  function handleConsider({
    detail: { items, info },
  }: CustomEvent<DndEvent<TimelineItem>>) {
    if (info.trigger === TRIGGERS.DRAG_STARTED) {
      dragOriginZone.set(zoneId);
    }

    timeline = items;
  }

  function handleFinalize({
    detail: { items, info },
  }: CustomEvent<DndEvent<TimelineItem>>) {
    const originZone = get(dragOriginZone);

    timeline = items;

    const draggedId = info.id;
    const newPosition = items.findIndex(({ id }) => id === draggedId);

    if (originZone === zoneId) {
      channel.push("reorder_timeline", {
        track_id: draggedId,
        position: newPosition,
      });
    } else {
      channel.push("extend_timeline", {
        position: newPosition,
      });
    }
  }
</script>

<Timeline
  items={timeline}
  onconsider={handleConsider}
  onfinalize={handleFinalize}
>
  {#snippet children(item)}
    <TrackCard revealed={!item.current} track={item.track} />
  {/snippet}
</Timeline>
