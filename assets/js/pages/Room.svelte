<script>
  import socket from "../user_socket.js";
  import { useChannel } from "../hooks/useChannel.svelte.js";

  let { room_id } = $props();

  let state = $state(null);
  let userCount = $state(0);

  useChannel({
    socket,
    topic: `room:${room_id}`,
    events: {
      game_state: (gameState) => {
        state = gameState;
        userCount = gameState.participants.length;
      },
    },
  });
</script>

<div
  class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-purple-400 via-pink-500 to-red-500"
>
  <div class="flex-1 flex items-center justify-center">
    <div class="text-center text-white max-w-4xl mx-auto px-6">
      {#if state}
        <!-- Circular Player Layout -->
        <div
          class="relative mx-auto mb-12"
          style="width: 60vw; height: 60vh; min-width: 400px; min-height: 400px;"
        >
          {#if state.participants && state.participants.length > 0}
            {#each state.participants as participant, index}
              {@const angle = (index * 360) / state.max_participants}
              {@const radius = 35}
              {@const x =
                Math.cos(((angle - 90) * Math.PI) / 180) * radius + 50}
              {@const y =
                Math.sin(((angle - 90) * Math.PI) / 180) * radius + 50}
              <div
                class="absolute transform -translate-x-1/2 -translate-y-1/2 transition-all duration-500"
                style="left: {x}%; top: {y}%;"
              >
                <div class="flex flex-col items-center">
                  <div
                    class="w-20 h-20 rounded-full bg-white/20 flex items-center justify-center border-4 border-white/30 shadow-lg hover:scale-110 transition-transform"
                  >
                    <img
                      src={participant.avatar_url}
                      alt={participant.name}
                      class="w-full h-full rounded-full object-cover"
                    />
                  </div>
                  <!-- Player name -->
                  <div
                    class="mt-2 text-sm font-medium text-white text-center px-2 py-1 bg-black/50 rounded-md backdrop-blur-sm"
                  >
                    {participant.name}
                  </div>
                </div>
              </div>
            {/each}
          {/if}

          <!-- Empty slots for remaining players -->
          {#each Array(state.max_participants - userCount) as _, index}
            {@const totalIndex = userCount + index}
            {@const angle = (totalIndex * 360) / state.max_participants}
            {@const radius = 35}
            {@const x = Math.cos(((angle - 90) * Math.PI) / 180) * radius + 50}
            {@const y = Math.sin(((angle - 90) * Math.PI) / 180) * radius + 50}
            <div
              class="absolute w-20 h-20 transform -translate-x-1/2 -translate-y-1/2"
              style="left: {x}%; top: {y}%;"
            >
              <div
                class="w-20 h-20 rounded-full border-4 border-dashed border-white/30 flex items-center justify-center"
              >
                <div class="text-4xl text-white/50 font-bold">?</div>
              </div>
            </div>
          {/each}

          <!-- Center circle with game info -->
          <div
            class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-24 h-24 rounded-full"
          ></div>
        </div>

        <!-- Game Controls -->
        <div class="flex flex-col items-center space-y-4">
          {#if state.status === "waiting"}
            <button
              class="bg-white text-purple-600 px-12 py-4 rounded-full font-semibold text-lg hover:bg-white/90 transition-colors shadow-lg"
            >
              Start Game
            </button>
          {/if}
        </div>
      {:else}
        <div class="flex flex-col items-center">
          <p class="text-lg opacity-90 mb-8">Connecting to game...</p>
          <!-- Loading spinner -->
          <div
            class="w-16 h-16 border-4 border-white/30 border-t-white rounded-full animate-spin"
          ></div>
        </div>
      {/if}
    </div>
  </div>
</div>
