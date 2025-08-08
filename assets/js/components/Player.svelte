<script>
  import { getChannelContext } from "@shared/context/channel.js";

  const { state, channel } = $derived(getChannelContext());

  let isPlayback = $derived(state?.player?.is_playback ?? false);
</script>

<div class="player">
  <button
    class="play"
    aria-label={isPlayback ? "Pause track" : "Play track"}
    onclick={() => {
      channel.push(isPlayback ? "pause_playback" : "start_playback", {});
    }}
  >
    {#if isPlayback}
      <svg class="icon" fill="currentColor" viewBox="0 0 24 24">
        <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
      </svg>
    {:else}
      <svg class="icon" fill="currentColor" viewBox="0 0 24 24">
        <path d="M8 5v14l11-7z" />
      </svg>
    {/if}
  </button>
</div>

<style>
  .player {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    background: rgba(255, 255, 255, 0.2);
    backdrop-filter: blur(0.5rem);
    border-top: 1px solid rgba(255, 255, 255, 0.3);
    padding: 1rem;
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .play {
    width: 3rem;
    height: 3rem;
    background: white;
    color: #6b46c1;
    border-radius: 0.5rem;
    font-weight: bold;
    border: none;
    cursor: pointer;
    box-shadow: 0 0.625rem 0.9375rem -0.1875rem rgba(0, 0, 0, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.3s ease;
  }

  .play:hover {
    background: rgba(255, 255, 255, 0.9);
    transform: scale(1.05);
  }

  .icon {
    width: 1.5rem;
    height: 1.5rem;
  }
</style>
