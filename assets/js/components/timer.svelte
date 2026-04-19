<script lang="ts">
  import { getGameContext } from "~/contexts/game";

  const session = getGameContext();
  const snapshot = $derived($session.snapshot);
  const game = $derived(snapshot?.game ?? null);
  const turn = $derived(game?.turn ?? null);
  const phase = $derived(turn?.phase);
  const deadlineAtMs = $derived.by(() => {
    if (turn?.phase !== "challenging") {
      return null;
    }

    return turn.deadline_at_ms ?? null;
  });

  let nowMs = $state(Date.now());
  let total = $state<number | null>(null);

  $effect(() => {
    if (deadlineAtMs === null) {
      total = null;
      return;
    }

    nowMs = Date.now();

    const interval = setInterval(() => {
      nowMs = Date.now();
    }, 250);

    return () => {
      clearInterval(interval);
    };
  });

  const seconds = $derived.by(() => {
    if (deadlineAtMs === null) {
      return null;
    }

    return Math.max(0, Math.ceil((deadlineAtMs - nowMs) / 1_000));
  });

  const formattedTime = $derived.by(() => {
    if (seconds === null) {
      return null;
    }

    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;

    return `${String(minutes).padStart(2, "0")}:${String(remainingSeconds).padStart(2, "0")}`;
  });

  $effect(() => {
    if (phase !== "challenging" || seconds === null) {
      total = null;
      return;
    }

    if (total === null || seconds > total) {
      total = seconds;
    }
  });

  const progress = $derived.by(() => {
    if (seconds === null || total === null || total === 0) {
      return 0;
    }

    return Math.min(1, Math.max(0, seconds / total));
  });

  const size = 84;
  const strokeWidth = 5;
  const center = size / 2;
  const radius = center - strokeWidth / 2;
  const circumference = 2 * Math.PI * radius;
  const dashOffset = $derived.by(() => circumference * (1 - progress));
</script>

{#if phase === "challenging" && formattedTime !== null}
  <div
    class="game-timer"
    aria-live="polite"
    aria-label={`Phase timer ${formattedTime}`}
    role="timer"
  >
    <svg
      class="game-timer__ring"
      viewBox={`0 0 ${size} ${size}`}
      aria-hidden="true"
    >
      <circle
        class="game-timer__track"
        cx={center}
        cy={center}
        r={radius}
        fill="none"
        stroke-width={strokeWidth}
      />
      <g transform={`rotate(-90 ${center} ${center})`}>
        <circle
          class="game-timer__progress"
          cx={center}
          cy={center}
          r={radius}
          fill="none"
          stroke-width={strokeWidth}
          stroke-dasharray={`${circumference} ${circumference}`}
          stroke-dashoffset={dashOffset}
          stroke-linecap="round"
        />
      </g>
    </svg>
    <span class="game-timer__value">{formattedTime}</span>
  </div>
{/if}

<style>
  .game-timer {
    position: relative;
    display: inline-grid;
    place-items: center;
    width: 5.25rem;
    height: 5.25rem;
    filter: drop-shadow(0 10px 18px rgba(0, 0, 0, 0.18));
  }

  .game-timer__ring {
    width: 100%;
    height: 100%;
    overflow: visible;
  }

  .game-timer__track {
    stroke: rgba(255, 255, 255, 0.14);
  }

  .game-timer__progress {
    stroke: var(--color-gold);
    filter: drop-shadow(0 0 6px rgba(250, 204, 21, 0.35));
    transition: stroke-dashoffset 200ms linear;
  }

  .game-timer__value {
    position: absolute;
    color: var(--color-white);
    font-size: clamp(1rem, 1.15vw, 1.25rem);
    font-weight: var(--font-weight-extrabold);
    line-height: 1;
    letter-spacing: -0.04em;
    font-variant-numeric: tabular-nums;
    font-feature-settings: "tnum" 1;
    text-align: center;
    text-shadow:
      0 2px 6px rgba(0, 0, 0, 0.38),
      0 0 10px rgba(0, 0, 0, 0.18);
  }

  @media (width < 640px) {
    .game-timer {
      width: 4.5rem;
      height: 4.5rem;
    }

    .game-timer__value {
      font-size: 1rem;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .game-timer__progress {
      transition: none;
    }
  }
</style>
