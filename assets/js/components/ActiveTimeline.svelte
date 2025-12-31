<script lang="ts">
  import { getScopeContext } from "~components/Scope.svelte";
  import { getGameContext } from "~components/GameChannel.svelte";
  import TrackCard from "~components/TrackCard.svelte";
  import Timeline from "~components/Timeline.svelte";
  import Draggable from "~components/Draggable.svelte";
  import { type DndEvent, TRIGGERS } from "svelte-dnd-action";
  import { dragOriginZone } from "~shared/stores/dragOrigin";
  import { get } from "svelte/store";
  import { TURN_PHASE } from "~shared/types/turn";
  import { PUSH_EVENT } from "~shared/types/channel";
  import type { User } from "~shared/types/user";

  const { state, channel } = $derived.by(getGameContext);
  const { user: currentPlayer } = $derived.by(getScopeContext);
  const currentTrack = $derived(state?.track);
  const zoneId = $derived(`participant-timeline-${currentPlayer.uuid}`);
  const turnPhase = $derived(state?.turn?.phase);

  const participants = $derived(
    new Map(state?.participants?.map((user) => [user.uuid, user]) ?? [])
  );

  const assumptions = $derived.by(() => {
    const assumptions = state?.turn?.assumptions || [];

    return assumptions.reduce((acc, { position, user_id }) => {
      acc.set(position, participants.get(user_id));

      return acc;
    }, new Map<number, User | undefined>());
  });

  let timeline = $derived.by(() => {
    const timeline = state?.turn?.timeline || [];

    return timeline.map((track, index) => ({
      id: `${track.id}-${assumptions.get(index)?.uuid}`,
      track,
      current: track.id === currentTrack?.id,
      user: assumptions.get(index),
    }));
  });

  type TimelineItem = (typeof timeline)[number];

  const activePlayerId = $derived.by(() => {
    return state?.queue?.[state?.cursor];
  });

  const canUserDragItem = (item: TimelineItem): boolean => {
    return item.user?.uuid === currentPlayer?.uuid;
  };

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

    const newPosition = items.findIndex((item) => item.id === info.id);

    if (originZone === zoneId) {
      channel.push(PUSH_EVENT.REORDER_TIMELINE, {
        position: newPosition,
      });
    } else {
      channel.push(PUSH_EVENT.MAKE_ASSUMPTION, {
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
    <Draggable draggable={canUserDragItem(item)}>
      <TrackCard
        revealed={!item.current || turnPhase === TURN_PHASE.RESULTS}
        track={item.track}
        user={item.user}
      />
    </Draggable>
  {/snippet}
</Timeline>
