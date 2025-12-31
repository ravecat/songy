<script lang="ts">
  import { getGameContext } from "~components/GameChannel.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import TrackCard from "~components/TrackCard.svelte";
  import Timeline from "~components/Timeline.svelte";
  import Draggable from "~components/Draggable.svelte";
  import { type DndEvent, TRIGGERS } from "svelte-dnd-action";
  import { dragOriginZone } from "~shared/stores/dragOrigin";
  import { TURN_PHASE } from "~shared/types/turn";

  const { state } = $derived.by(getGameContext);
  const { user } = $derived.by(getScopeContext);
  const zoneId = $derived(`current-track-${user.uuid}`);

  const shouldShow = $derived.by(() => {
    const phase = state?.turn?.phase;
    const currentTrack = state?.track;
    const assumptions = state?.turn?.assumptions || [];
    const userHasAssumption = assumptions.some(
      (assumption) => assumption.user_id === user.uuid
    );

    const activePlayerUuid = state?.queue?.[state?.cursor];
    const isActivePlayer = activePlayerUuid === user.uuid;

    if (!currentTrack) return false;

    switch (phase) {
      case TURN_PHASE.READY:
        return isActivePlayer && !userHasAssumption;
      case TURN_PHASE.CHALLENGING:
        return !isActivePlayer && !userHasAssumption;
      default:
        return false;
    }
  });

  let timeline = $derived.by(() => {
    const currentTrack = state?.track;

    return currentTrack
      ? [
          {
            id: `${currentTrack.id}-${user.uuid}`,
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

{#if shouldShow}
  <Timeline
    items={timeline}
    onconsider={handleConsider}
    onfinalize={handleFinalize}
    dropFromOthersDisabled={true}
  >
    {#snippet children(item)}
      <Draggable draggable={true}>
        <TrackCard revealed={false} track={item.track} />
      </Draggable>
    {/snippet}
  </Timeline>
{/if}
