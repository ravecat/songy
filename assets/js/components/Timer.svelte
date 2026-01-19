<script lang="ts">
  import { getGameContext } from "~components/GameChannel.svelte";
  import { BROADCAST_EVENT } from "~shared/types/channel";
  import { TURN_PHASE } from "~shared/types/turn";

  const { channel, game } = $derived.by(getGameContext);
  const phase = $derived(game?.turn?.phase);

  let seconds = $state<number | null>(null);
  let total = $state<number | null>(null);

  $effect(() => {
    const ref = channel.on(BROADCAST_EVENT.TIMER, ({ remaining }) => {
      if (total === null) {
        total = remaining;
      }
      seconds = remaining;
    });

    return () => {
      channel.off(BROADCAST_EVENT.TIMER, ref);
    };
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

{#if phase === TURN_PHASE.CHALLENGING && seconds !== null}
  <div class="timer">
    <svg
      viewBox={`0 0 ${size} ${size}`}
      aria-live="polite"
      role="timer"
      style="width: 100%; height: 100%;"
    >
      <g transform={`rotate(-90 ${center} ${center})`}>
        <circle
          class="stroke-white/90 transition-[stroke-dashoffset] duration-200"
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
        class="fill-white text-sm font-bold tracking-[0.05em]"
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
  .timer {
    width: 3rem;
    height: 3rem;
  }
</style>

