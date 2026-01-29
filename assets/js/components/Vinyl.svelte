<script lang="ts">
  import type { Track } from "~shared/types/track";

  interface Props {
    track: Track | null;
  }

  let { track }: Props = $props();
</script>

<div class="vinyl-disc">
  <div class="vinyl-disc__grooves"></div>
  <div
    class="vinyl-disc__label"
    class:vinyl-disc__label_fallback={!track?.cover_url}
  >
    {#if track?.cover_url}
      <img src={track.cover_url} alt={track.title} class="vinyl-disc__label-cover" />
    {/if}
  </div>
</div>

<style>
  .vinyl-disc {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 50%, #1a1a1a 100%);
    box-shadow:
      0 4px 16px rgba(0, 0, 0, 0.5),
      inset 0 0 40px rgba(0, 0, 0, 0.3);
    display: flex;
    align-items: center;
    justify-content: center;
    animation: spin 8s linear infinite;
  }

  @keyframes spin {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }

  .vinyl-disc__grooves {
    position: absolute;
    inset: 8px;
    border-radius: 50%;
    background: repeating-radial-gradient(
      circle at center,
      transparent 0px,
      transparent 2px,
      rgba(60, 60, 60, 0.3) 2px,
      rgba(60, 60, 60, 0.3) 4px
    );
  }

  .vinyl-disc__label {
    width: 50px;
    height: 50px;
    border-radius: 50%;
    background: #1a1a1a;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1;
    overflow: hidden;
  }

  .vinyl-disc__label_fallback {
    background: linear-gradient(135deg, #facc15, #f97316);
    box-shadow: inset 0 2px 4px rgba(255, 255, 255, 0.3);
  }

  .vinyl-disc__label-cover {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover;
  }
</style>
