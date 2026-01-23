<script lang="ts">
  import TrackCard from "~components/TrackCard.svelte";
  import { getGameContext } from "~components/GameChannel.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import type { User } from "~shared/types/user";
  import { PUSH_EVENT } from "~shared/types/channel";

  const { game, permissions, channel } = $derived.by(getGameContext);
  const { user: currentUser } = $derived.by(getScopeContext);
  const currentTrack = $derived(game?.track);

  const participants = $derived(
    new Map(game?.participants?.map((user) => [user.uuid, user]) ?? []),
  );

  const assumptions = $derived.by(() => {
    const assumptions = game?.turn?.assumptions || [];

    return assumptions.reduce((acc, { position, user_id }) => {
      acc.set(position, participants.get(user_id));

      return acc;
    }, new Map<number, User | undefined>());
  });

  const activePlayerAssumptionPosition = $derived.by(() => {
    const activePlayerId = game?.queue?.[game?.cursor ?? 0];

    // If current user is the active player, don't sync (they're already scrolling)
    if (currentUser?.uuid === activePlayerId) return null;

    // Find position where active player made assumption
    for (const [position, user] of assumptions.entries()) {
      if (user?.uuid === activePlayerId) {
        return position;
      }
    }

    return null;
  });

  let hasInteracted = $state(false);
  let lastScrolledPosition = $state<number | null>(null);

  let tracks = $derived.by(() => {
    const timeline = game?.turn?.timeline || [];

    return timeline.map((track, index) => ({
      id: `${track?.id}-${assumptions.get(index)?.uuid}`,
      track,
      current: track?.id === currentTrack?.id,
      user: assumptions.get(index),
    }));
  });

  let timeline: HTMLDivElement;

  function handleWheel(e: WheelEvent) {
    hasInteracted = true;
    if (Math.abs(e.deltaX) > Math.abs(e.deltaY)) return;
    e.preventDefault();
    timeline.scrollLeft += e.deltaY;
  }

  function onScrollEnd() {
    if (!hasInteracted) return;

    const rect = timeline.getBoundingClientRect();
    const el = document.elementFromPoint(
      rect.left + rect.width / 2,
      rect.top + rect.height / 2,
    ) as HTMLElement;

    const position = el?.dataset?.index;

    channel.push(PUSH_EVENT.MAKE_ASSUMPTION, { position });
  }

  function scrollToIndex(index: number) {
    if (!timeline) return;

    const snapElement = timeline.querySelector(
      `[data-index="${index}"]`,
    ) as HTMLElement;
    snapElement?.scrollIntoView({
      behavior: "smooth",
      block: "nearest",
      inline: "center",
    });
  }

  $effect(() => {
    const position = activePlayerAssumptionPosition;

    if (
      position === null ||
      position === lastScrolledPosition ||
      hasInteracted
    ) {
      return;
    }

    scrollToIndex(position);
    lastScrolledPosition = position;
  });
</script>

<div class="timeline">
  <div
    class="timeline__scroll"
    bind:this={timeline}
    onwheel={handleWheel}
    onscrollend={onScrollEnd}
    onpointerdown={() => (hasInteracted = true)}
    ontouchmove={() => (hasInteracted = true)}
    role="list"
  >
    <span class="timeline__snap" data-index={0}></span>
    {#each tracks as { user, track, current, id }, i (id)}
      <div class="timeline__item" role="listitem">
        <TrackCard
          revealed={!current || permissions?.can_see_assumptions}
          {track}
          {user}
        />
      </div>
      <span class="timeline__snap" data-index={Math.min(i + 1, tracks.length)}
      ></span>
    {/each}
  </div>
  {#if permissions?.can_make_assumptions && currentTrack}
    <TrackCard revealed={false} track={currentTrack} />
  {/if}
</div>

<style>
  .timeline {
    display: flex;
    flex-direction: column;
    flex: 1;
    align-items: center;
    justify-content: center;
    gap: 1rem;
  }

  .timeline__scroll {
    display: flex;
    width: 100%;
    overflow-x: auto;
    overflow-y: hidden;
    scroll-snap-type: x mandatory;
    scroll-behavior: smooth;
    scrollbar-width: none;
  }

  .timeline__scroll::before,
  .timeline__scroll::after {
    content: "";
    flex-shrink: 0;
    width: 50%;
  }

  .timeline__snap {
    width: 1.5rem;
    flex-shrink: 0;
    scroll-snap-align: center;
  }

  .timeline__item {
    flex: 0 0 auto;
    display: flex;
    justify-content: center;
  }
</style>
