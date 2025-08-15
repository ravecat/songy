<script lang="ts">
  import type { Track } from "~shared/types/track";

  interface TrackCardProps {
    /** Track data to display */
    track: Track;
    /** Whether the track card is revealed (shows content) */
    revealed?: boolean;
    /** Whether the track is in ready state */
    ready?: boolean;
  }

  let { track, revealed = true, ready = false }: TrackCardProps = $props();
</script>

<div class="wrapper">
  <div
    class="track-card"
    style:transform={revealed ? "rotateY(0)" : ""}
    aria-label={revealed
      ? `Track: ${track.artist} - ${track.title} (${track.year})`
      : "Hidden track card"}
  >
    {#if revealed}
      <div
        class="front"
        aria-label={`Track: ${track.artist} - ${track.title} (${track.year})`}
      >
        <div class="card-content">
          <div class="artist-text">
            {#if track.artist && track.artist.length > 12}
              <div
                class="marquee"
                style="--speed: {Math.max(6, track.artist.length * 0.2)}s"
              >
                <div class="marquee-track">
                  <span>{track.artist}</span>
                  <span aria-hidden="true">{track.artist}</span>
                </div>
              </div>
            {:else}
              <div class="text-overflow-container">{track.artist || ""}</div>
            {/if}
          </div>
          <div class="year-container">
            <span class="year-text">
              {track.year || ""}
            </span>
          </div>
          <div class="title-text">
            {#if track.title && track.title.length > 12}
              <div
                class="marquee"
                style="--speed: {Math.max(6, track.title.length * 0.2)}s"
              >
                <div class="marquee-track">
                  <span>{track.title}</span>
                  <span aria-hidden="true">{track.title}</span>
                </div>
              </div>
            {:else}
              <div class="text-overflow-container">{track.title || ""}</div>
            {/if}
          </div>
        </div>
      </div>
    {/if}

    {#if !revealed}
      <div class="back" aria-label="Hidden track card">
        <div class="card-content">
          <div class="year-text">?</div>
          {#if ready}
            <button
              class="btn"
              aria-label="Mark as ready to submit guess"
              type="button"
            >
              Ready
            </button>
          {/if}
        </div>
      </div>
    {/if}
  </div>
</div>

<style>
  .wrapper {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    perspective: 1000px;
  }

  .track-card {
    position: relative;
    width: 8rem;
    height: 8rem;
    background: linear-gradient(135deg, #facc15, #f97316);
    border-radius: 0.5rem;
    transform: rotateY(180deg);
    transition: transform 0.4s;
    transform-style: preserve-3d;
    padding: 0;
    user-select: none;
    box-shadow:
      0 10px 15px -3px rgba(0, 0, 0, 0.1),
      0 4px 6px -2px rgba(0, 0, 0, 0.05);
  }

  .front,
  .back {
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
    border-radius: 0.5rem;
    box-sizing: border-box;
  }

  .back {
    transform: rotateY(180deg);
  }

  .card-content {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    mask-image: linear-gradient(
      to right,
      transparent,
      black 1rem,
      black calc(100% - 1rem),
      transparent
    );
  }

  .artist-text {
    color: #1f2937;
    font-weight: 600;
    margin-bottom: 0.5rem;
    font-size: 0.875rem;
  }

  .year-container {
    margin-bottom: 0.5rem;
  }

  .year-text {
    font-size: 2.25rem;
    font-weight: 700;
    color: #000000;
    line-height: 1;
    letter-spacing: 0.025em;
    display: inline-block;
  }

  .title-text {
    font-size: 0.875rem;
    font-style: italic;
    color: #1f2937;
  }

  @keyframes scaleIn {
    0% {
      transform: scale(0);
      opacity: 0;
    }
    100% {
      transform: scale(1);
      opacity: 1;
    }
  }

  .text-overflow-container {
    white-space: nowrap;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .marquee {
    overflow: clip;
    width: 100%;
  }

  .marquee-track {
    display: flex;
    width: max-content;
    will-change: transform;
    animation: marquee var(--speed, 8s) linear infinite;
  }

  .marquee-track > span {
    padding-right: 2rem;
    flex-shrink: 0;
  }

  .marquee:hover .marquee-track {
    animation-play-state: paused;
  }

  @keyframes marquee {
    to {
      transform: translateX(-50%);
    }
  }
</style>
