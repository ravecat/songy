<script lang="ts">
  import type { Snippet } from "svelte";

  interface Props {
    /** Slot content for the label center */
    children?: Snippet;
    /** Animation duration in seconds */
    duration?: number;
    /** Keep label stationary while disc spins */
    still?: boolean;
  }

  let { children, duration = 8, still = false }: Props = $props();
</script>

<div class="vinyl-disc" style="--spin-duration: {duration}s">
  <div class="vinyl-disc__grooves"></div>
  <div class="vinyl-disc__shine"></div>
  <div class="vinyl-disc__lint"></div>
  <div
    class="vinyl-disc__label"
    class:vinyl-disc__label_counter-rotate={still}
  >
    {#if children}
      {@render children()}
    {:else}
      <svg class="vinyl-disc__label-pattern" viewBox="0 0 100 100">
        <defs>
          <clipPath id="label-clip">
            <circle cx="50" cy="50" r="50" />
          </clipPath>
        </defs>
        <g clip-path="url(#label-clip)">
          <rect width="100" height="100" fill="#2e3440" />
          <polygon points="-5,0 15,0 -5,20" fill="#d08770" opacity="0.7" />
          <polygon points="25,0 55,0 -5,60 -5,30" fill="#bf616a" opacity="0.7" />
          <polygon points="65,0 90,0 -5,95 -5,70" fill="#5e81ac" opacity="0.7" />
          <polygon points="100,0 100,15 10,105 -5,105 -5,100" fill="#88c0d0" opacity="0.7" />
          <polygon points="100,25 100,50 35,115 15,115" fill="#a3be8c" opacity="0.7" />
          <polygon points="100,60 100,80 60,120 45,120" fill="#ebcb8b" opacity="0.7" />
          <polygon points="100,90 100,105 85,120 75,120" fill="#b48ead" opacity="0.7" />
        </g>
      </svg>
    {/if}
  </div>
  <div class="vinyl-disc__spindle"></div>
</div>

<style>
  .vinyl-disc {
    width: 100%;
    height: 100%;
    border-radius: var(--radius-circle);
    background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 50%, #1a1a1a 100%);
    box-shadow:
      var(--shadow-glass),
      inset 0 0 40px rgba(0, 0, 0, 0.3);
    display: flex;
    align-items: center;
    justify-content: center;
    animation: spin var(--spin-duration) var(--ease-linear) infinite;
  }

  @keyframes spin {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }

  @keyframes counter-spin {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(-360deg);
    }
  }

  .vinyl-disc__grooves {
    position: absolute;
    inset: 8px;
    border-radius: var(--radius-circle);
    background: repeating-radial-gradient(
      circle at center,
      transparent 0px,
      transparent 2px,
      rgba(60, 60, 60, 0.3) 2px,
      rgba(60, 60, 60, 0.3) 4px
    );
  }

  .vinyl-disc__shine {
    position: absolute;
    inset: 0;
    border-radius: var(--radius-circle);
    background:
      /* Sector wear marks - arc-shaped light reflections along grooves */
      conic-gradient(
        from 15deg at 50% 50%,
        transparent 0deg,
        rgba(255, 255, 255, 0.03) 8deg,
        transparent 15deg,
        transparent 45deg,
        rgba(255, 255, 255, 0.025) 52deg,
        transparent 58deg,
        transparent 120deg,
        rgba(255, 255, 255, 0.02) 128deg,
        transparent 135deg,
        transparent 200deg,
        rgba(255, 255, 255, 0.035) 210deg,
        transparent 220deg,
        transparent 280deg,
        rgba(255, 255, 255, 0.02) 290deg,
        transparent 300deg,
        transparent 340deg,
        rgba(255, 255, 255, 0.015) 350deg,
        transparent 360deg
      ),
      /* Radial wear rings */
        repeating-radial-gradient(
          circle at center,
          transparent 20%,
          rgba(255, 255, 255, 0.045) 21%,
          transparent 22%,
          transparent 35%,
          rgba(255, 255, 255, 0.05) 36%,
          transparent 37%,
          transparent 55%,
          rgba(255, 255, 255, 0.048) 56%,
          transparent 57%,
          transparent 75%,
          rgba(255, 255, 255, 0.052) 76%,
          transparent 77%
        );
    pointer-events: none;
  }

  /* Lint/fiber caught in grooves */
  .vinyl-disc__lint {
    position: absolute;
    inset: 0;
    border-radius: var(--radius-circle);
    pointer-events: none;
  }

  .vinyl-disc__lint::before,
  .vinyl-disc__lint::after {
    content: "";
    position: absolute;
    background: rgba(255, 255, 255, 0.13);
    border-radius: 1px;
  }

  /* First fiber - curved */
  .vinyl-disc__lint::before {
    width: 12px;
    height: 1.5px;
    top: 28%;
    left: 62%;
    transform: rotate(35deg);
    box-shadow:
      18px 45px 0 rgba(255, 255, 255, 0.11),
      -80px 30px 0 rgba(255, 255, 255, 0.1);
  }

  /* Second fiber - different angle */
  .vinyl-disc__lint::after {
    width: 8px;
    height: 1px;
    top: 68%;
    left: 25%;
    transform: rotate(-20deg);
    box-shadow: 60px -35px 0 rgba(255, 255, 255, 0.12);
  }

  .vinyl-disc__label {
    /* Real vinyl label is ~36% of disc diameter */
    width: 36%;
    height: 36%;
    border-radius: var(--radius-circle);
    background: linear-gradient(135deg, var(--color-gold), var(--color-orange));
    box-shadow: inset 0 2px 4px rgba(255, 255, 255, 0.3);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1;
    overflow: hidden;
  }

  .vinyl-disc__label_counter-rotate {
    animation: counter-spin var(--spin-duration) var(--ease-linear) infinite;
  }

  .vinyl-disc__label-pattern {
    width: 100%;
    height: 100%;
  }

  .vinyl-disc__spindle {
    position: absolute;
    width: 2.5%;
    height: 2.5%;
    border-radius: var(--radius-circle);
    background: linear-gradient(135deg, #4c566a 0%, #2e3440 100%);
    box-shadow:
      inset 0 1px 2px rgba(255, 255, 255, 0.2),
      0 1px 3px rgba(0, 0, 0, 0.4);
    z-index: 2;
  }
</style>
