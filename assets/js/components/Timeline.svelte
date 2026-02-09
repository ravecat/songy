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

  function scrollTimeline(direction: -1 | 1) {
    hasInteracted = true;
    const item = timeline.querySelector<HTMLElement>("[role='listitem']");
    if (!item) return;
    const step = item.offsetWidth + parseFloat(getComputedStyle(timeline).gap);
    timeline.scrollBy({ left: direction * step, behavior: "smooth" });
  }

  function onScrollEnd() {
    if (!hasInteracted) return;

    const centerX =
      timeline.getBoundingClientRect().left + timeline.offsetWidth / 2;

    const closestElement = Array.from(
      timeline.querySelectorAll<HTMLElement>("[role='listitem']"),
    ).reduce((closest, el) => {
      const distance = Math.abs(
        el.getBoundingClientRect().left + el.offsetWidth / 2 - centerX,
      );
      const closestDistance = Math.abs(
        closest.getBoundingClientRect().left +
          closest.offsetWidth / 2 -
          centerX,
      );
      return distance < closestDistance ? el : closest;
    });

    const position = closestElement?.dataset.position;

    if (!position) return;

    channel.push(PUSH_EVENT.MAKE_ASSUMPTION, { position: Number(position) });
  }
</script>

<div class="timeline">
  <button
    class="timeline__nav"
    onclick={() => scrollTimeline(-1)}
    aria-label="Scroll left"
  >
    <ChevronLeft size={20} strokeWidth={2.5} />
  </button>

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

  <button
    class="timeline__nav"
    onclick={() => scrollTimeline(1)}
    aria-label="Scroll right"
  >
    <ChevronRight size={20} strokeWidth={2.5} />
  </button>
</div>

<style>
  .timeline {
    display: flex;
    align-items: center;
    width: 100%;
  }

  .timeline__scroll {
    --item-size: 8rem;
    --gap: 1rem;

    display: flex;
    flex: 1;
    min-width: 0;
    gap: var(--gap);
    overflow-x: auto;
    overflow-y: hidden;
    scroll-snap-type: x mandatory;
    scroll-behavior: smooth;
    overscroll-behavior-x: contain;
    scrollbar-width: none;
  }

  .timeline__scroll::before,
  .timeline__scroll::after {
    content: "";
    flex-shrink: 0;
    width: 50%;
  }

  .timeline__nav {
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 2.5rem;
    height: 2.5rem;
    background: transparent;
    border: none;
    border-radius: 0.5rem;
    color: white;
    cursor: pointer;
  }

  .timeline__nav:hover {
    background-color: rgba(255, 255, 255, 0.1);
  }

  .timeline__nav:active {
    background-color: rgba(255, 255, 255, 0.2);
  }

  .timeline__placeholder {
    width: 8rem;
    height: 8rem;
    flex-shrink: 0;
    scroll-snap-align: center;
    background: linear-gradient(135deg, #facc15, #f97316);
    border-radius: var(--radius-md);
    opacity: var(--opacity-subtle);
    border: var(--border-thick) dashed rgba(255, 255, 255, 0.2);
    display: flex;
    align-items: center;
    justify-content: center;
    user-select: none;
  }

  .timeline__placeholder_track {
    opacity: var(--opacity-full);
    background: none;
    border: none;
  }

  .timeline__assumption-avatar {
    width: 4rem;
    height: 4rem;
    border-radius: var(--radius-circle);
    overflow: hidden;
    border: var(--border-thick) solid rgba(255, 255, 255, 0.5);
    box-shadow: var(--shadow-base);
  }

  .timeline__assumption-avatar img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
</style>
