<script>
  import { getChannelContext } from "@shared/context/channel.js";

  const { state, channel } = $derived(getChannelContext());
  
  let isPlayback = $derived(state?.player?.is_playback ?? false);
</script>

<div class="flex justify-center">
  <button
    class="w-full px-8 py-4 bg-white text-purple-600 rounded-lg font-bold text-xl hover:bg-white/90 transition-all duration-300 hover:scale-105 shadow-2xl border-4 border-white/50 flex items-center justify-center gap-3"
    aria-label={isPlayback ? "Pause track" : "Play track"}
    onclick={() => {
      channel.push(
        isPlayback ? "pause_playback" : "start_playback",
        {}
      );
    }}
  >
    {#if isPlayback}
      <!-- Pause icon (two vertical bars) -->
      <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
        <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
      </svg>
      Pause
    {:else}
      <!-- Play icon (triangle) -->
      <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
        <path d="M8 5v14l11-7z" />
      </svg>
      Play
    {/if}
  </button>
</div>
