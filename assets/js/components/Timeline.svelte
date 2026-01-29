<!--
  Timeline Component

  Displays the active player's timeline with tracks and assumption slots.
  Players scroll horizontally to select a position for their assumption.

  ## Position System

  Position is an index in a virtual timeline that contains tracks and assumptions.
  When a new assumption is inserted, all positions to the right shift by +1.

  User timeline:       -      A      -      B      -      C      -
  Virtual timeline: [slot] - [A] - [slot] - [B] - [slot] - [C] - [slot]
  Positions:           0            1            2            3

  - User timeline: actual tracks owned by the player
  - Virtual timeline: UI representation with slots between tracks
  - Position: index where assumption can be placed (between/around tracks)

  ## Example Flow (3 tracks: A, B, C)

  ### Initial State

  User timeline:       -      A      -      B      -      C      -
  Virtual timeline: [slot] - [A] - [slot] - [B] - [slot] - [C] - [slot]
  Positions:           0            1            2            3
  Assumptions: []
  Available: 0, 1, 2, 3

  ### Step 1: U1 places at position 1

  User timeline:       -      A      -      B      -      C      -
  Virtual timeline: [slot] - [A] - [U1] - [B] - [slot] - [C] - [slot]
  Positions:           0            1            3            4
  Assumptions: [{pos: 1, user: U1}]
  Available: 0, 3, 4

  ### Step 2: U2 places at position 3 (slot after B)

  User timeline:       -      A      -      B      -      C      -
  Virtual timeline: [slot] - [A] - [U1] - [B] - [U2] - [C] - [slot]
  Positions:           0            1            3            5
  Assumptions: [{pos: 1, user: U1}, {pos: 3, user: U2}]
  Available: 0, 5

  ### Step 3: U3 places at position 0 (slot before A) — triggers shift!

  User timeline:       -      A      -      B      -      C      -
  Virtual timeline: [U3] - [A] - [U1] - [B] - [U2] - [C] - [slot]
  Positions:          0           2           4            6
  Assumptions: [{pos: 2, user: U1}, {pos: 4, user: U2}, {pos: 0, user: U3}]
  (U1: 1→2, U2: 3→4 shifted because pos >= 0)
  Available: 6

  ### Step 4: U4 places at position 6 (slot after C)

  User timeline:       -      A      -      B      -      C      -
  Virtual timeline: [U3] - [A] - [U1] - [B] - [U2] - [C] - [U4]
  Positions:          0           2           4           6
  Assumptions: [{pos: 2, user: U1}, {pos: 4, user: U2}, {pos: 0, user: U3}, {pos: 6, user: U4}]
  Available: none

  ## Key Rules

  1. Virtual timeline length is constant: 2 * tracks + 1
  2. Assumptions replace slots, total element count stays the same
  3. Inserting at position P shifts all existing assumptions with pos >= P by +1

  ## Backend Sync (lib/songy/boundary/game.ex)

  Frontend sends position via MAKE_ASSUMPTION event.
  Backend validates and stores in game.turn.assumptions.

  Backend validation (update_assumptions):
  - Blocked if abs(existing_pos - new_pos) <= 1 (prevents adjacent assumptions)
  - On insert: shifts all assumptions with pos >= new_pos by +1
  - On update (same user): simply changes position, no shift

  Storage format: [%{position: integer, user_id: string}, ...]
-->
<script lang="ts">
  import TrackCard from "~components/TrackCard.svelte";
  import { getGameContext } from "~components/GameChannel.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";

  const { game, channel } = $derived.by(getGameContext);
  const { user: currentUser } = $derived.by(getScopeContext);
  const activePlayerId = $derived.by(() => game?.queue?.[game?.cursor ?? 0]);

  const participants = $derived(
    new Map(game?.participants?.map((user) => [user.uuid, user]) ?? []),
  );

  const assumptions = $derived(
    new Map(
      game?.turn?.assumptions?.map(({ position, user_id }) => [
        position,
        participants.get(user_id),
      ]),
    ),
  );

  const activeTimeline = $derived.by(() =>
    activePlayerId ? game?.timelines?.[activePlayerId] || [] : [],
  );

  let hasInteracted = $state(false);

  const cells = $derived.by(() => {
    const items = [];
    let assumptionsBefore = 0;

    for (let i = 0; i <= activeTimeline.length; i++) {
      const position = i + assumptionsBefore;
      const user = assumptions.get(position);
      const isCurrentUser = user?.uuid === currentUser?.uuid;

      items.push(
        user
          ? { kind: "assumption", position, user }
          : { kind: "slot", position },
      );

      if (user && !isCurrentUser) assumptionsBefore++;

      if (i < activeTimeline.length) {
        items.push({ kind: "track", track: activeTimeline[i] });
      }
    }

    return items;
  });

  let timeline: HTMLDivElement;

  function handleWheel(e: WheelEvent) {
    hasInteracted = true;
    if (Math.abs(e.deltaX) > Math.abs(e.deltaY)) return;
    e.preventDefault();
    timeline.scrollLeft += e.deltaY;
  }

  function onScrollEnd() {
    if (!hasInteracted || !timeline) return;

    const timelineRect = timeline.getBoundingClientRect();
    const centerX = timelineRect.left + timelineRect.width / 2;

    let closestElement: Element | null = null;
    let minDistance = Infinity;

    timeline.querySelectorAll("[role='listitem']").forEach((el) => {
      const rect = el.getBoundingClientRect();
      const elementCenterX = rect.left + rect.width / 2;
      const distance = Math.abs(elementCenterX - centerX);

      if (distance < minDistance) {
        minDistance = distance;
        closestElement = el;
      }
    });

    const closestPosition = closestElement
      ? (closestElement as HTMLElement).dataset.position
      : undefined;

    if (closestPosition === undefined) return;

    channel.push(PUSH_EVENT.MAKE_ASSUMPTION, {
      position: Number(closestPosition),
    });
  }
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
    aria-label="Timeline"
  >
    {#each cells as cell, index (index)}
      <div
        class="timeline__placeholder"
        class:timeline__placeholder_track={cell.kind !== "slot"}
        data-position={cell.kind === "track" ? undefined : cell.position}
        role="listitem"
      >
        {#if cell.kind === "track"}
          <TrackCard track={cell.track} />
        {:else if cell.kind === "assumption"}
          <TrackCard track={null} revealed={false}>
            {#snippet back()}
              <div class="timeline__assumption-avatar">
                <img src={cell.user.avatar_url} alt={cell.user.name} />
              </div>
            {/snippet}
          </TrackCard>
        {/if}
      </div>
    {/each}
  </div>
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
    gap: 1rem;
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

  .timeline__placeholder {
    width: 8rem;
    height: 8rem;
    flex-shrink: 0;
    scroll-snap-align: center;
    background: linear-gradient(135deg, #facc15, #f97316);
    border-radius: 0.5rem;
    opacity: 0.3;
    border: 2px dashed rgba(255, 255, 255, 0.2);
    display: flex;
    align-items: center;
    justify-content: center;
    user-select: none;
  }

  .timeline__placeholder_track {
    opacity: 1;
    background: none;
    border: none;
  }

  .timeline__assumption-avatar {
    width: 4rem;
    height: 4rem;
    border-radius: 50%;
    overflow: hidden;
    border: 2px solid rgba(255, 255, 255, 0.5);
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  }

  .timeline__assumption-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
</style>
