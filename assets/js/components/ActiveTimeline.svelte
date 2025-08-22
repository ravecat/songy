<script lang="ts">
  import { getScopeContext } from "~components/Scope.svelte";
  import { getGameContext } from "~components/GameContext.svelte";
  import TrackCard from "~components/TrackCard.svelte";
  import Timeline from "~components/Timeline.svelte";
  import { type DndEvent, TRIGGERS } from "svelte-dnd-action";
  import { dragOriginZone } from "~shared/stores/dragOrigin";
  import { get } from "svelte/store";
  import { TURN_PHASE } from "~shared/types/turn";
  import { PUSH_EVENT } from "~shared/types/channel";
  import type { User } from "~shared/types/user";

  const { state, channel } = $derived.by(getGameContext);
  const { user: currentPlayer } = $derived.by(getScopeContext);
  const currentTrack = $derived(state?.turn?.track);
  const zoneId = $derived(`participant-timeline-${currentPlayer.uuid}`);
  const turnPhase = $derived(state?.turn?.phase);

  const assumptions = $derived.by(() => {
    const assumptions = state?.turn?.assumptions || [];
    const participants = state?.participants || [];

    const map: Record<number, User | null> = {};

    assumptions.forEach(({ position, user_id }) => {
      const user = participants.find((p) => p.uuid === user_id);

      if (user) {
        map[position] = user;
      }
    });

    return map;
  });

  let timeline = $derived.by(() => {
    const timeline = state?.turn?.timeline || [];

    return timeline.map((track, index) => ({
      id: track.id,
      track,
      current: track.id === currentTrack?.id,
      user: assumptions[index],
    }));
  });

  const activePlayerUuid = $derived.by(() => {
    return state?.turn?.queue?.[state?.turn?.cursor];
  });
  const activePlayer = $derived.by(() => {
    return state?.participants?.find(({ uuid }) => uuid === activePlayerUuid);
  });

  const isActivePlayer = $derived.by(() => {
    return activePlayer?.uuid == currentPlayer?.uuid;
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
      channel.push(PUSH_EVENT.REORDER_TIMELINE, {
        track_id: draggedId,
        position: newPosition,
      });
    } else {
      channel.push(PUSH_EVENT.MAKE_ASSUMPTION, {
        position: newPosition,
      });
    }
  }

  const handleSteady = () => {
    channel.push(PUSH_EVENT.NEXT_PHASE, {});
  };
</script>

<Timeline
  items={timeline}
  onconsider={handleConsider}
  onfinalize={handleFinalize}
>
  {#snippet children(item)}
    <TrackCard
      revealed={!item.current}
      track={item.track}
      ready={item.current && turnPhase === TURN_PHASE.STEADY && isActivePlayer}
      user={item.user}
      onsteady={handleSteady}
    />
  {/snippet}
</Timeline>
