<script lang="ts">
  import TrackCard from "~components/TrackCard.svelte";
  import { getGameContext } from "~components/GameChannel.svelte";
  import type { User } from "~shared/types/user";
  import { PUSH_EVENT } from "~shared/types/channel";

  const { game, permissions, channel } = $derived.by(getGameContext);
  const currentTrack = $derived(game?.track);

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

  let hasInteracted = $state(false);

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
      rect.top + rect.height / 2
    ) as HTMLElement;

    const position = el?.dataset?.index;

    channel.push(PUSH_EVENT.MAKE_ASSUMPTION, { position });
  }
</script>

<div class="relative flex flex-1 flex-col items-center justify-center gap-4">
  <div
    class="timeline"
    bind:this={timeline}
    onwheel={handleWheel}
    onscrollend={onScrollEnd}
    onpointerdown={() => (hasInteracted = true)}
    ontouchmove={() => (hasInteracted = true)}
    role="list"
  >
    <span class="snap" data-index={0}></span>
    {#each tracks as { user, track, current, id }, i (id)}
      <div class="card" role="listitem">
        <TrackCard
          revealed={!current || permissions?.can_see_assumptions}
          {track}
          {user}
        />
      </div>
      <span class="snap" data-index={Math.min(i + 1, tracks.length)}></span>
    {/each}
  </div>
  {#if permissions?.can_make_assumptions}
    <TrackCard revealed={false} track={currentTrack} />
  {/if}
</div>

<style>
  .timeline {
    display: flex;
    width: 100%;
    overflow-x: auto;
    overflow-y: hidden;
    scroll-snap-type: x mandatory;
    scroll-behavior: smooth;
    scrollbar-width: none;
  }

  .timeline::before,
  .timeline::after {
    content: "";
    flex-shrink: 0;
    width: 50%;
  }

  .snap {
    width: 1.5rem;
    flex-shrink: 0;
    scroll-snap-align: center;
  }

  .card {
    flex: 0 0 auto;
    display: flex;
    justify-content: center;
  }
</style>
