<script lang="ts">
  interface TimerProps {
    seconds: number | null;
  }

  let { seconds }: TimerProps = $props();
  let total = $state<number | null>(null);

  $effect(() => {
    if (total === null) {
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

{#if seconds !== null}
  <svg
    class="fixed left-4 top-4 z-50 h-16 w-16 pointer-events-none select-none"
    viewBox={`0 0 ${size} ${size}`}
    aria-live="polite"
    role="timer"
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
{/if}

