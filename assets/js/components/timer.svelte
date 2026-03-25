<script lang="ts">
  import { getGameContext } from "~/contexts/game";

  const session = $derived.by(getGameContext);
  const game = $derived(session.game);
  const phase = $derived(game?.turn?.phase);

  let total = $state<number | null>(null);
  const seconds = $derived.by(() => session.timer ?? null);

  $effect(() => {
    if (phase !== "challenging" || seconds === null) {
      total = null;
      return;
    }

    if (total === null || seconds > total) {
      total = seconds;
    }
  });

  const size = 36;
  const strokeWidth = 2;
  const center = size / 2;
  const radius = center - strokeWidth / 2;
  const circumference = 2 * Math.PI * radius;

  const progress = $derived.by(() => {
    if (seconds === null || total === null || total === 0) {
      return 0;
    }

    return Math.min(1, Math.max(0, seconds / total));
  });

  const dashOffset = $derived.by(() => circumference * (1 - progress));
</script>

{#if phase === "challenging" && seconds !== null}
  <div class="game-timer">
    <svg
      viewBox={`0 0 ${size} ${size}`}
      aria-live="polite"
      role="timer"
      style="width: 100%; height: 100%;"
    >
      <g transform={`rotate(-90 ${center} ${center})`}>
        <circle
          class="game-timer__circle stroke-white/90 transition-[stroke-dashoffset] duration-200"
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
      <text
        class="game-timer__text fill-white text-sm font-bold tracking-[0.05em]"
        x={center}
        y={center}
        text-anchor="middle"
        dominant-baseline="middle"
      >
        {seconds}
      </text>
    </svg>
  </div>
{/if}

<style>
  .game-timer {
    width: 3rem;
    height: 3rem;
  }
</style>
