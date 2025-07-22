<script>
  import { scale } from "svelte/transition";
  import { getChannelContext } from "@shared/context/channel.js";

  const { state, channel } = $derived(getChannelContext());

  let isPlayback = $derived(state?.player?.is_playback ?? false);
</script>

<div
  in:scale={{ duration: 400 }}
  out:scale={{ duration: 400, start: 0 }}
  class="flex justify-center py-16"
>
  <button
    class="w-32 h-32 bg-white text-purple-600 rounded-lg font-bold hover:bg-white/90 transition-all duration-300 hover:scale-105 shadow-2xl border-4 border-white/50 flex items-center justify-center"
    aria-label={isPlayback ? "Pause track" : "Play track"}
    onclick={() => {
      channel.push(isPlayback ? "pause_playback" : "start_playback", {});
    }}
  >
    {#if isPlayback}
      <svg class="w-16 h-16" fill="currentColor" viewBox="0 0 24 24">
        <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
      </svg>
    {:else}
      <svg class="w-16 h-16" fill="currentColor" viewBox="0 0 24 24">
        <path d="M8 5v14l11-7z" />
      </svg>
    {/if}
  </button>
</div>
