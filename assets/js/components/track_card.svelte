<script lang="ts">
  import type { Snippet } from "svelte";
  import type { Track } from "~shared/types/track";

  interface TrackCardProps {
    /** Track data to display (null for assumption cards) */
    track: Track | null;
    /** Whether the track card is revealed (shows content) */
    revealed?: boolean;
    /** Custom content for card back */
    back?: Snippet;
  }

  let { track, revealed = true, back }: TrackCardProps = $props();
</script>

<div class="track-card">
  <div
    class={["track-card__inner", { "track-card__inner_revealed": revealed }]}
  >
    <div class="track-card__front" aria-hidden={!revealed}>
      {#if revealed && track}
        <div class="track-card__artist">
          {#if track.artist?.length > 12}
            <div
              class="track-card__marquee"
              style="--speed: {Math.max(6, track.artist.length * 0.2)}s"
            >
              <div class="track-card__marquee-track">
                <span>{track.artist}</span>
                <span aria-hidden="true">{track.artist}</span>
              </div>
            </div>
          {:else}
            {track.artist ?? ""}
          {/if}
        </div>
        <div class="track-card__year">
          {track.year ?? ""}
        </div>
        <div class="track-card__title">
          {#if track.title?.length > 12}
            <div
              class="track-card__marquee"
              style="--speed: {Math.max(6, track.title.length * 0.2)}s"
            >
              <div class="track-card__marquee-track">
                <span>{track.title}</span>
                <span aria-hidden="true">{track.title}</span>
              </div>
            </div>
          {:else}
            {track.title ?? ""}
          {/if}
        </div>
      {/if}
    </div>

    <div
      class="track-card__back"
      aria-hidden={revealed}
      aria-label="Hidden track card"
    >
      {#if !revealed && back}
        {@render back()}
      {/if}
    </div>
  </div>
</div>

<style>
  .track-card {
    perspective: 1000px;
  }

  .track-card__inner {
    position: relative;
    width: 8rem;
    height: 8rem;
    background:
      linear-gradient(
        160deg,
        rgba(255, 255, 255, 0.15) 0%,
        transparent 40%
      ),
      linear-gradient(135deg, #facc15, #e87b10);
    border: 1px solid rgba(255, 255, 255, 0.18);
    border-radius: var(--radius-card);
    transform: rotateY(180deg);
    transition: transform var(--animation-base);
    transform-style: preserve-3d;
    user-select: none;
    box-shadow: var(--shadow-card);
  }

  /* Noise grain overlay */
  .track-card__inner::after {
    content: "";
    position: absolute;
    inset: 0;
    border-radius: inherit;
    background: var(--noise-url);
    background-size: 128px 128px;
    pointer-events: none;
    mix-blend-mode: overlay;
  }

  .track-card__inner_revealed {
    transform: rotateY(0deg);
  }

  .track-card__front,
  .track-card__back {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    position: absolute;
    width: 100%;
    height: 100%;
    left: 0;
    top: 0;
    backface-visibility: hidden;
    gap: 0.35rem;
    mask-image: linear-gradient(
      to right,
      transparent,
      black 1rem,
      black calc(100% - 1rem),
      transparent
    );
  }

  .track-card__front[aria-hidden="true"],
  .track-card__back[aria-hidden="true"] {
    visibility: hidden;
    pointer-events: none;
  }

  .track-card__back {
    transform: rotateY(180deg);
  }

  .track-card__artist {
    font-weight: var(--font-weight-bold);
    font-size: var(--font-size-xs);
    text-transform: uppercase;
    letter-spacing: 0.1em;
    opacity: 0.85;
  }

  .track-card__year {
    font-size: var(--font-size-2xl);
    font-weight: var(--font-weight-bold);
    line-height: 1;
    letter-spacing: -0.02em;
    text-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
  }

  .track-card__title {
    font-size: var(--font-size-sm);
    font-style: italic;
    opacity: 0.7;
  }

  .track-card__marquee {
    overflow: clip;
    width: 100%;
  }

  .track-card__marquee-track {
    display: flex;
    width: max-content;
    will-change: transform;
    animation: marquee var(--speed, 8s) linear infinite;
  }

  .track-card__marquee-track > span {
    padding-right: 2rem;
    flex-shrink: 0;
  }

  .track-card__marquee:hover .track-card__marquee-track {
    animation-play-state: paused;
  }

  @keyframes marquee {
    to {
      transform: translateX(-50%);
    }
  }
</style>
