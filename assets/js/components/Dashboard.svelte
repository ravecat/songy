<script>
  import { slide } from "svelte/transition";
  import { getChannelContext } from "@shared/context/channel.js";
  import Participant from "@components/Participant.svelte";
  import WaitingSlot from "@components/WaitingSlot.svelte";

  const { state, channel } = $derived(getChannelContext());

  let userCount = $derived(state?.participants?.length ?? 0);
  let isPlayback = $derived(state?.player?.is_playback ?? false);
  let isWaiting = $derived(state?.status === "waiting");
</script>

<div
  class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-purple-400 via-pink-500 to-red-500"
>
  <div class="flex-1 flex items-center justify-center">
    <div class="text-center text-white mx-auto px-6 min-w-[24rem]">
      {#if state}
        <!-- Players List Layout - KEEPING AS IS FOR NOW -->
        <div class="space-y-2 mb-2">
          {#if state.participants && state.participants.length > 0}
            {#each state.participants as participant}
              <Participant {participant} />
            {/each}
          {/if}

          <!-- Empty slots for remaining players -->
          {#if isWaiting}
            <div
              in:slide={{ duration: 400, axis: "y" }}
              out:slide={{ duration: 400, axis: "y" }}
            >
              {#each Array(state.max_participants - userCount) as _, index}
                <WaitingSlot />
              {/each}
            </div>
          {/if}
        </div>

        <!-- Control Button - KEEPING AS IS FOR NOW -->
        <div class="flex justify-center">
          {#if state.status === "waiting"}
            <button
              class="w-full px-8 py-4 bg-white text-purple-600 rounded-lg font-bold text-xl hover:bg-white/90 transition-all duration-300 hover:scale-105 shadow-2xl border-4 border-white/50"
              onclick={() => channel.push("start_game", {})}
            >
              Start
            </button>
          {:else if state.status === "in_progress"}
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
          {/if}
        </div>
      {:else}
        <!-- Loading spinner - KEEPING AS IS FOR NOW -->
        <div class="flex flex-col items-center">
          <p class="text-lg opacity-90 mb-8">Connecting to game...</p>
          <div
            class="w-16 h-16 border-4 border-white/30 border-t-white rounded-full animate-spin"
            role="status"
            aria-label="Loading"
          ></div>
        </div>
      {/if}
    </div>
  </div>
</div>
