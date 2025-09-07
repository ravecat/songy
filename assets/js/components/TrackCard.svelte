<script lang="ts">
  import type { Track } from "~shared/types/track";
  import type { User } from "~shared/types/user";

  interface TrackCardProps {
    /** Track data to display */
    track: Track;
    /** Whether the track card is revealed (shows content) */
    revealed?: boolean;
    /** User who made assumption for this position (only for hidden tracks) */
    user?: User | null;
  }

  let { track, revealed = true, user = null }: TrackCardProps = $props();
</script>

<div class="wrapper">
  <div class={["card", { revealed }]}>
    <div class="front" aria-hidden={!revealed}>
      {#if revealed}
        <div class="artist-text">
          {#if track?.artist?.length > 12}
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
            {track?.artist ?? ""}
          {/if}
        </div>
        <div class="year-text">
          {track?.year ?? ""}
        </div>
        <div class="title-text">
          {#if track?.title?.length > 12}
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
            {track.title || ""}
          {/if}
        </div>
      {/if}
    </div>

    <div class="back" aria-hidden={revealed} aria-label="Hidden track card">
      {#if !revealed}
        {#if user?.avatar_url}
          <img
            src={user.avatar_url}
            alt={user.name}
            class="avatar ring-primary ring-offset-base-100 w-16 rounded-full ring-2 ring-offset-2"
          />
        {:else}
          <div class="year-text">?</div>
        {/if}
      {/if}
    </div>
  </div>
</div>

<style>
  .wrapper {
    perspective: 1000px;
  }

  .card {
    position: relative;
    width: 8rem;
    height: 8rem;
    background: linear-gradient(135deg, #facc15, #f97316);
    border-radius: 0.5rem;
    transform: rotateY(180deg);
    transition: transform 0.4s;
    transform-style: preserve-3d;
    user-select: none;
    box-shadow:
      0 10px 15px -3px rgba(0, 0, 0, 0.1),
      0 4px 6px -2px rgba(0, 0, 0, 0.05);
  }

  .card.revealed {
    transform: rotateY(0deg);
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
    gap: 0.5rem;
    mask-image: linear-gradient(
      to right,
      transparent,
      black 1rem,
      black calc(100% - 1rem),
      transparent
    );
  }

  .front[aria-hidden="true"],
  .back[aria-hidden="true"] {
    visibility: hidden;
    pointer-events: none;
  }

  .back {
    transform: rotateY(180deg);
  }

  .artist-text {
    font-weight: 600;
    font-size: 0.875rem;
  }

  .year-text {
    font-size: 2.25rem;
    font-weight: 700;
    line-height: 1;
    letter-spacing: 0.025em;
  }

  .title-text {
    font-size: 0.875rem;
    font-style: italic;
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
