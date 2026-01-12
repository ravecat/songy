<script lang="ts">
  import TrackCard from "~components/TrackCard.svelte";
  import { getGameContext } from "~components/GameChannel.svelte";
  import { TURN_PHASE } from "~shared/types/turn";
  import type { User } from "~shared/types/user";

  const { game } = $derived.by(getGameContext);
  const currentTrack = $derived(game?.track);
  const phase = $derived(game?.turn?.phase);

  const participants = $derived(
    new Map(game?.participants?.map((user) => [user.uuid, user]) ?? [])
  );

  $inspect(game?.turn?.assumptions);

  const assumptions = $derived.by(() => {
    const assumptions = game?.turn?.assumptions || [];

    return assumptions.reduce((acc, { position, user_id }) => {
      acc.set(position, participants.get(user_id));

      return acc;
    }, new Map<number, User | undefined>());
  });

  let tracks = $derived.by(() => {
    const timeline = game?.turn?.timeline || [];

    return timeline.map((track, index) => ({
      id: `${track.id}-${assumptions.get(index)?.uuid}`,
      track,
      current: track.id === currentTrack?.id,
      user: assumptions.get(index),
    }));
  });

  let timeline: HTMLDivElement;

  function handleWheel(e: WheelEvent) {
    if (Math.abs(e.deltaX) > Math.abs(e.deltaY)) return;
    e.preventDefault();
    timeline.scrollLeft += e.deltaY;
  }

  function onScrollEnd() {
    const rect = timeline.getBoundingClientRect();
    const el = document.elementFromPoint(
      rect.left + rect.width / 2,
      rect.top + rect.height / 2
    ) as HTMLElement;

    console.log("Snap:", el?.dataset.index);
  }
</script>

<div class="relative flex flex-1 flex-col items-center justify-center gap-4">
  <div
    class="timeline"
    bind:this={timeline}
    onwheel={handleWheel}
    onscrollend={onScrollEnd}
  >
    <span class="snap" data-index={0}></span>
    {#each tracks as { user, track, current, id }, i (id)}
      <div class="card">
        <TrackCard
          revealed={!current || phase === TURN_PHASE.RESULTS}
          {track}
          {user}
        />
      </div>
      <span class="snap" data-index={i + 1}></span>
    {/each}
  </div>
  <TrackCard revealed={false} track={currentTrack} />
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
