<script lang="ts">
  import { getGameContext } from "~components/GameContext.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import TrackCard from "~components/TrackCard.svelte";
  import Timeline from "~components/Timeline.svelte";
  import { type DndEvent, TRIGGERS } from "svelte-dnd-action";
  import { dragOriginZone } from "~shared/stores/dragOrigin";
  import { TURN_PHASE } from "~/shared/types/turn";

  const { state } = $derived.by(getGameContext);
  const { user } = $derived.by(getScopeContext);
  const currentTrack = $derived(state?.turn?.track);
  const zoneId = $derived(`current-track-${user.uuid}`);

  let timeline = $derived.by(() => {
    return currentTrack
      ? [
          {
            id: currentTrack.id,
            track: currentTrack,
            current: true,
          },
        ]
      : [];
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
