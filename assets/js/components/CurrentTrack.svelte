<script lang="ts">
  import { getChannelContext } from "~shared/context/channel";
  import { getScopeContext } from "~shared/context/scope";
  import TrackCard from "~components/TrackCard.svelte";
  import Timeline from "~components/Timeline.svelte";
  import { type DndEvent, TRIGGERS } from "svelte-dnd-action";
  import { dragOriginZone } from "~shared/stores/dragOrigin";

  const { state } = $derived.by(getChannelContext);
  const { user } = $derived.by(getScopeContext);
  const currentTrack = $derived(state?.turn?.track);
  const zoneId = $derived(`current-track-${user?.uuid}`);
  const currentUserTimeline = $derived(state?.timelines?.[user?.uuid] || []);

  let timeline = $derived.by(() => {
    if (!currentTrack) return [];

    const isCurrentTrackInProcess = currentUserTimeline.some(
      ({ id }) => id === currentTrack.id
    );

    return isCurrentTrackInProcess
      ? []
      : [
          {
            id: currentTrack.id,
            track: currentTrack,
            current: true,
          },
        ];
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
    if (info.trigger === TRIGGERS.DROPPED_INTO_ANOTHER) {
      timeline = [];
    } else {
      timeline = items;
    }

    dragOriginZone.set(null);
  }
</script>

<Timeline
  items={timeline}
  onconsider={handleConsider}
  onfinalize={handleFinalize}
  dropFromOthersDisabled={true}
>
  {#snippet children(item)}
    <TrackCard revealed={false} track={item.track} />
  {/snippet}
</Timeline>
