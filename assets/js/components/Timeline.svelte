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

  ### Step 3: U3 places at position 0 (slot before A) - triggers shift!

  User timeline:       -      A      -      B      -      C      -
  Virtual timeline: [U3] - [A] - [U1] - [B] - [U2] - [C] - [slot]
  Positions:          0           2           4            6
  Assumptions: [{pos: 2, user: U1}, {pos: 4, user: U2}, {pos: 0, user: U3}]
  (U1: 1->2, U2: 3->4 shifted because pos >= 0)
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
  import Equalizer from "~components/Equalizer.svelte";
  import { getGameContext } from "~components/GameChannel.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";
  import { fade } from "svelte/transition";
  import { ChevronLeft, ChevronRight } from "lucide-svelte";
  import type { Track } from "~shared/types/track";
  import type { User } from "~shared/types/user";

  type SlotCell = { kind: "slot"; position: number };
  type TrackCell = { kind: "track"; track: Track };
  type AssumptionCell = { kind: "assumption"; position: number; user: User };
  type TimelineCell = SlotCell | TrackCell | AssumptionCell;

  const { game, channel } = $derived.by(getGameContext);
  const { user: currentUser } = $derived.by(getScopeContext);
  const activePlayerId = $derived(game?.queue?.[game?.cursor]);
  const participants = $derived(game?.participants ?? {});
  const assumptions = $derived(game?.turn?.assumptions ?? {});

  const activeTimeline = $derived(game?.timelines?.[activePlayerId] ?? []);

  let hasInteracted = $state(false);
  let activeCellIndex = $state<number | null>(null);

  const cells = $derived.by((): TimelineCell[] => {
    const items: TimelineCell[] = [];
    let assumptionsCountBefore = 0;

    for (let i = 0; i <= activeTimeline.length; i++) {
      const position = i + assumptionsCountBefore;
      const userId = assumptions[position];
      const user = userId ? participants[userId] : undefined;
      const isCurrentUser = user?.uuid === currentUser?.uuid;

      if (user) {
        items.push({ kind: "assumption", position, user });
      } else {
        items.push({ kind: "slot", position });
      }

      if (user && !isCurrentUser) assumptionsCountBefore++;

      if (i < activeTimeline.length) {
        items.push({ kind: "track", track: activeTimeline[i]! });
      }
    }

    return items;
  });

  let timeline: HTMLDivElement;

  function handleWheel(e: WheelEvent) {
    hasInteracted = true;
    if (Math.abs(e.deltaX) > Math.abs(e.deltaY)) return;
    e.preventDefault();
    timeline.scrollLeft += e.deltaY * 0.5;
  }

  function findCenterCell():
    | { element: HTMLElement; index: number }
    | undefined {
    const centerX =
      timeline.getBoundingClientRect().left + timeline.offsetWidth / 2;
    const allCells =
      timeline.querySelectorAll<HTMLElement>("[role='listitem']");
    const snapTargets = timeline.querySelectorAll<HTMLElement>("[data-snap]");

    let closestSlot: HTMLElement | undefined;
    let closestDistance = Infinity;

    snapTargets.forEach((el) => {
      const distance = Math.abs(
        el.getBoundingClientRect().left + el.offsetWidth / 2 - centerX,
      );
      if (distance < closestDistance) {
        closestDistance = distance;
        closestSlot = el;
      }
    });

    if (!closestSlot) return undefined;

    const index = Array.from(allCells).indexOf(closestSlot);
    return { element: closestSlot, index };
  }

  function onScrollEnd() {
    if (!hasInteracted) return;

    const closest = findCenterCell();

    if (closest) {
      activeCellIndex = closest.index;
    }

    const position = closest?.element.dataset.position;
    if (!position) return;

    channel.push(PUSH_EVENT.MAKE_ASSUMPTION, { position: Number(position) });
  }
</script>

<div class="timeline__wrapper">
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
      {@const isSlot = cell.kind === "slot"}
      {@const isOwnAssumption = cell.kind === "assumption" && cell.user.uuid === currentUser?.uuid}
      {@const isSnap = isSlot || isOwnAssumption}
      {@const isActive = hasInteracted && activeCellIndex === index}
      <div
        class="timeline__cell"
        class:timeline__cell_slot={isSlot}
        class:timeline__cell_own-assumption={isOwnAssumption}
        class:timeline__cell-active={isActive}
        aria-label={cell.kind === "assumption" ? `${cell.user.name}'s assumption` : undefined}
        data-snap={isSnap ? "" : undefined}
        data-position={cell.kind !== "track" ? cell.position : undefined}
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
        {:else if cell.kind === "slot"}
          <Equalizer size={32} />
        {/if}
      </div>
    {/each}
  </div>

  <p class="timeline__hint" transition:fade={{ duration: 600 }}>
    <ChevronLeft
      size={16}
      strokeWidth={2}
      aria-hidden="true"
      class="timeline__hint-chevron"
    />
    swipe to place your guess
    <ChevronRight
      size={16}
      strokeWidth={2}
      aria-hidden="true"
      class="timeline__hint-chevron"
    />
  </p>
</div>

<style>
  .timeline__wrapper {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: 100%;
    flex: 1;
    min-height: 0;
    overflow: hidden;
  }

  .timeline__scroll {
    display: flex;
    width: 100%;
    padding-block: 1.5rem;
    overflow-x: auto;
    overflow-y: clip;
    scroll-snap-type: x mandatory;
    scroll-behavior: smooth;
    overscroll-behavior-x: contain;
    scrollbar-width: none;
    mask-image: linear-gradient(
      to right,
      transparent,
      black 3%,
      black 97%,
      transparent
    );
  }

  .timeline__scroll::before,
  .timeline__scroll::after {
    content: "";
    flex-shrink: 0;
    width: 50%;
  }

  /* --- Cell base --- */

  .timeline__cell {
    width: 8rem;
    height: 8rem;
    flex-shrink: 0;
    margin-inline: 0.5rem;
    display: flex;
    align-items: center;
    justify-content: center;
    user-select: none;
    transition:
      transform 0.25s var(--ease-out),
      box-shadow 0.25s var(--ease-out);
  }

  /* --- Snap targets (slots + own assumption) --- */

  .timeline__cell_slot,
  .timeline__cell_own-assumption {
    scroll-snap-align: center;
  }

  /* --- Slot (empty drop zone) --- */

  .timeline__cell_slot {
    background: linear-gradient(
      135deg,
      var(--color-gold-8) 0%,
      var(--color-orange-6) 100%
    );
    border-radius: var(--radius-card);
    border: var(--border-thick) solid var(--color-gold-50);
    animation: shimmer 2.4s var(--ease-in-out) infinite;
    opacity: 1;
  }

  .timeline__cell_slot:nth-child(even) {
    animation-delay: var(--delay-xxl);
  }

  /* --- Active cell (center-snapped) --- */

  .timeline__cell-active {
    transform: scale(1.05);
    z-index: var(--z-above);
  }

  .timeline__cell-active.timeline__cell_slot {
    background: linear-gradient(
      135deg,
      var(--color-gold-25) 0%,
      var(--color-orange-18) 100%
    );
    border-style: solid;
    border-width: 3px;
    border-color: var(--color-gold);
    animation: shimmer-active 1.4s var(--ease-in-out) infinite;
  }

  /* --- Track/Assumption cells (no slot styling) --- */

  .timeline__cell:not(.timeline__cell_slot) {
    background: none;
    outline: none;
    animation: none;
    opacity: var(--opacity-full);
  }

  .timeline__cell-active:not(.timeline__cell_slot) {
    filter: none;
  }

  /* --- Assumption avatar --- */

  .timeline__assumption-avatar {
    width: 4rem;
    height: 4rem;
    border-radius: var(--radius-circle);
    overflow: hidden;
    border: var(--border-thick) solid var(--color-white-emphasis);
    box-shadow: var(--shadow-base);
  }

  .timeline__assumption-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  /* --- Hint text --- */

  .timeline__hint {
    margin: 0;
    display: flex;
    align-items: center;
    gap: var(--spacing-xs);
    font-size: var(--font-size-sm);
    color: var(--color-white-emphasis);
    pointer-events: none;
  }

  .timeline__hint :global(.timeline__hint-chevron) {
    opacity: var(--opacity-muted);
    animation: hint-nudge 1.4s var(--ease-in-out) infinite;
  }

  .timeline__hint :global(.timeline__hint-chevron:first-child) {
    animation-name: nudge-left;
  }

  .timeline__hint :global(.timeline__hint-chevron:last-child) {
    animation-name: nudge-right;
  }

  /* --- Reduced motion --- */

  @media (prefers-reduced-motion: reduce) {
    .timeline__cell_slot {
      animation: none;
      opacity: 1;
      border-color: var(--color-gold-60);
      box-shadow: inset 0 0 14px var(--color-gold-20);
    }

    .timeline__cell-active {
      transform: none;
    }

    .timeline__cell-active.timeline__cell_slot {
      animation: none;
      border-style: solid;
      border-color: var(--color-gold-85);
      box-shadow:
        inset 0 0 20px var(--color-gold-25),
        0 0 14px var(--color-gold-30);
    }

    .timeline__hint {
      opacity: var(--opacity-muted);
    }

    .timeline__hint :global(.timeline__hint-chevron) {
      animation: none;
    }
  }
</style>
