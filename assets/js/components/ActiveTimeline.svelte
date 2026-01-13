<script lang="ts">
  import { getScopeContext } from "~components/Scope.svelte";
  import { getGameContext } from "~components/GameChannel.svelte";
  import TrackCard from "~components/TrackCard.svelte";
  import Timeline from "~components/Timeline.svelte";
  import Draggable from "~components/Draggable.svelte";
  import { type DndEvent, TRIGGERS } from "svelte-dnd-action";
  import { TURN_PHASE } from "~shared/types/turn";
  import { PUSH_EVENT } from "~shared/types/channel";
  import type { User } from "~shared/types/user";

  const { game, channel } = $derived.by(getGameContext);
  const { user: currentPlayer } = $derived.by(getScopeContext);
  const currentTrack = $derived(game?.track);
  const turnPhase = $derived(game?.turn?.phase);

  const participants = $derived(
    new Map(game?.participants?.map((user) => [user.uuid, user]) ?? [])
  );

  const assumptions = $derived.by(() => {
    const assumptions = game?.turn?.assumptions || [];

    return assumptions.reduce((acc, { position, user_id }) => {
      acc.set(position, participants.get(user_id));

      return acc;
    }, new Map<number, User | undefined>());
  });

  let timeline = $derived.by(() => {
    const timeline = game?.turn?.timeline || [];

    return timeline.map((track, index) => ({
      id: `${track.id}-${assumptions.get(index)?.uuid}`,
      track,
      current: track.id === currentTrack?.id,
      user: assumptions.get(index),
    }));
  });

  type Card = (typeof timeline)[number];

  const canUserDragItem = (item: Card): boolean => {
    return item.user?.uuid === currentPlayer?.uuid;
  };

  function handleConsider({ detail: { items } }: CustomEvent<DndEvent<Card>>) {
    timeline = items;
  }

  function handleFinalize({
    detail: { items, info },
  }: CustomEvent<DndEvent<Card>>) {
    timeline = items;

    if (
      info.trigger === TRIGGERS.DROPPED_INTO_ANOTHER ||
      info.trigger === TRIGGERS.DROPPED_OUTSIDE_OF_ANY
    ) {
      return;
    }

    const newPosition = items.findIndex((item) => item.id === info.id);

    channel.push(PUSH_EVENT.MAKE_ASSUMPTION, {
      position: newPosition,
    });
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
