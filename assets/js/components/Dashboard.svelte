<script>
  import { getChannelContext } from "@shared/context/channel.js";

  const { state, channel } = $derived(getChannelContext());

  let userCount = $derived(state?.participants?.length ?? 0);
  let isPlayback = $derived(state?.player?.is_playback ?? false);
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
              <div
                class="flex items-center p-2 bg-white/20 backdrop-blur-sm rounded-lg border border-white/30 shadow-lg transition-all duration-300 hover:bg-white/30"
              >
                <div
                  class="w-16 h-16 rounded-lg bg-white/20 flex-shrink-0 overflow-hidden border-2 border-white/30"
                >
                  <img
                    src={participant.avatar_url}
                    alt={participant.name}
                    class="w-full h-full object-cover"
                  />
                </div>
                <div class="ml-4 text-left">
                  <div class="text-lg font-medium text-white">
                    {participant.name}
                  </div>
                </div>
              </div>
            {/each}
          {/if}

          <!-- Empty slots for remaining players -->
          {#each Array(state.max_participants - userCount) as _}
            <div
              class="flex items-center p-2 bg-white/10 backdrop-blur-sm rounded-lg border-2 border-dashed border-white/30"
            >
              <div
                class="w-16 h-16 rounded-lg bg-white/10 flex-shrink-0 flex items-center justify-center"
              >
                <div class="text-2xl text-white/50 font-bold">?</div>
              </div>
              <div class="ml-4 text-left">
                <div class="text-lg font-medium text-white/50">
                  Waiting for player
                </div>
              </div>
            </div>
          {/each}
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
