<script>
  import socket from "../user_socket.js";
  import { useChannel } from "../hooks/useChannel.svelte.js";

  let { room_id } = $props();

  let userCount = $state(0);

  useChannel({
    socket,
    topic: `room:${room_id}`,
    events: {
      game_state: (payload) => {
        console.log("Game state:", payload);
        userCount = payload.participant_count || 0;
      }
    },
    onJoin: (payload) => {
      console.log("Joined room:", payload);
      userCount = payload.participant_count || 0;
    }
  });
</script>

<div
  class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-purple-400 via-pink-500 to-red-500"
>
  <div class="flex-1 flex items-center justify-center">
    <div class="text-center text-white">
      <h1 class="text-4xl font-bold mb-4">{room_id}</h1>
      <p class="text-lg opacity-90">Game starting soon...</p>

      <!-- User Count -->
      <div class="mt-6 bg-white/10 backdrop-blur-sm rounded-xl p-4">
        <h3 class="text-xl font-semibold mb-2">Players Online</h3>
        <div class="text-3xl font-bold">{userCount}</div>
      </div>
    </div>
  </div>
</div>
