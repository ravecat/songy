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
        console.log("Game state:", gameState);
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
      <h1 class="text-4xl font-bold mb-4">{room_id}</h1>
      
      {#if state}
        <!-- Game Status -->
        <div class="mb-6">
          <div class="inline-flex items-center px-4 py-2 bg-white/20 backdrop-blur-sm rounded-full">
            <div class="w-3 h-3 bg-green-400 rounded-full mr-2"></div>
            <span class="capitalize">{state.status}</span>
          </div>
        </div>

        <!-- Player Count Progress -->
        <div class="mb-8 bg-white/10 backdrop-blur-sm rounded-xl p-6">
          <h3 class="text-xl font-semibold mb-4">Players</h3>
          <div class="text-3xl font-bold mb-2">{userCount} / {state.max_participants}</div>
          
          <!-- Progress Bar -->
          <div class="w-full bg-white/20 rounded-full h-2 mb-6">
            <div 
              class="bg-white h-2 rounded-full transition-all duration-300" 
              style="width: {(userCount / state.max_participants) * 100}%"
            ></div>
          </div>

          <!-- Participants List -->
          {#if state.participants && state.participants.length > 0}
            <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
              {#each state.participants as participant}
                <div class="text-center">
                  <div class="w-16 h-16 mx-auto mb-2 rounded-full bg-white/20 flex items-center justify-center">
                    {#if participant.avatar_url}
                      <img 
                        src={participant.avatar_url} 
                        alt={participant.name || 'Player'} 
                        class="w-full h-full rounded-full"
                      />
                    {:else}
                      <div class="text-2xl">👤</div>
                    {/if}
                  </div>
                  <div class="text-sm truncate">
                    {participant.name || `Player ${participant.uuid.slice(0, 6)}`}
                  </div>
                </div>
              {/each}
            </div>
          {:else}
            <p class="text-white/70">Waiting for players to join...</p>
          {/if}
        </div>

        <!-- Game Controls -->
        {#if state.status === 'waiting'}
          <div class="space-y-4">
            {#if userCount >= 2}
              <button class="bg-white text-purple-600 px-8 py-3 rounded-full font-semibold hover:bg-white/90 transition-colors">
                Start Game
              </button>
            {:else}
              <p class="text-white/70">Need at least 2 players to start</p>
            {/if}
          </div>
        {:else if state.status === 'in_progress'}
          <p class="text-lg">Game in progress...</p>
        {:else if state.status === 'finished'}
          <button class="bg-white text-purple-600 px-8 py-3 rounded-full font-semibold hover:bg-white/90 transition-colors">
            Start New Game
          </button>
        {/if}
      {:else}
        <p class="text-lg opacity-90">Connecting to game...</p>
      {/if}
    </div>
  </div>
</div>
