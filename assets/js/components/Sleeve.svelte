<script lang="ts">
  import type { Track } from "~shared/types/track";

  interface Props {
    track: Track | null;
  }

  let { track }: Props = $props();
</script>

<div class="sleeve">
  {#if track?.cover_url}
    <img
      src={track.cover_url}
      alt={track.title}
      class="sleeve__cover-img"
    />
  {/if}

  <div class="sleeve__info">
    <div class="sleeve__artist">{track?.artist ?? "Unknown Artist"}</div>
    <div class="sleeve__title">{track?.title ?? "Unknown Track"}</div>
  </div>
  <div class="sleeve__year">{track?.year ?? ""}</div>
</div>

<style>
  .sleeve {
    position: relative;
    width: 220px;
    height: 220px;
    background: linear-gradient(
      145deg,
      #2a1f1a 0%,
      #3d2e26 40%,
      #2a1f1a 100%
    );
    border-radius: 4px;
    box-shadow:
      0 8px 32px rgba(0, 0, 0, 0.5),
      inset 0 1px 0 rgba(255, 255, 255, 0.05);
  }

  .sleeve__cover-img {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 4px;
    opacity: 0.3;
  }

  .sleeve__info {
    position: absolute;
    top: 1rem;
    left: 1rem;
    z-index: 2;
    max-width: 130px;
  }

  .sleeve__year {
    position: absolute;
    bottom: 1rem;
    left: 1rem;
    font-size: 2rem;
    font-weight: 800;
    background: linear-gradient(135deg, #facc15, #f97316);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    line-height: 1;
  }

  .sleeve__artist {
    font-size: 1rem;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.9);
    line-height: 1.2;
  }

  .sleeve__title {
    font-size: 0.875rem;
    font-style: italic;
    color: rgba(255, 255, 255, 0.6);
    margin-top: 0.25rem;
    line-height: 1.3;
  }
</style>
