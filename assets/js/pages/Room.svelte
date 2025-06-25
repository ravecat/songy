<script>
  import socket from "../user_socket.js";
  import { useChannel } from "../hooks/useChannel.svelte.js";

  let { room_id } = $props();

  let userCount = $state(0);
  let users = $state([]);
  let current_user = $state(null);

  useChannel({
    socket,
    topic: `room:${room_id}`,
    onJoin: (resp) => {
      current_user = resp.current_user;
    },
    events: {
      presence_state: updatePresence,
      presence_diff: updatePresenceDiff,
    },
  });

  function updatePresence(state) {
    users = Object.entries(state).map(([uuid, data]) => ({
      uuid,
      ...data.metas[0],
    }));
    userCount = users.length;
  }

  function updatePresenceDiff(diff) {
    if (diff.joins) {
      Object.entries(diff.joins).forEach(([uuid, data]) => {
        const existingIndex = users.findIndex((u) => u.uuid === uuid);
        const user = { uuid, ...data.metas[0] };

        if (existingIndex >= 0) {
          users[existingIndex] = user;
        } else {
          users = [...users, user];
        }
      });
    }

    if (diff.leaves) {
      Object.keys(diff.leaves).forEach((uuid) => {
        users = users.filter((u) => u.uuid !== uuid);
      });
    }

    userCount = users.length;
  }
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

  <!-- Current User Info -->
  {#if current_user}
    <div class="w-full p-6">
      <div
        class="max-w-md mx-auto bg-white/10 backdrop-blur-sm rounded-xl p-4 text-white"
      >
        <div class="flex items-center space-x-4">
          <img
            src={current_user.avatar_url}
            alt="User avatar"
            class="w-12 h-12 rounded-full bg-white/20 p-1"
          />
          <div>
            <p class="font-semibold text-lg">{current_user.name}</p>
            <p class="text-sm opacity-75">
              ID: {current_user.uuid.slice(0, 8)}...
            </p>
          </div>
        </div>
      </div>
    </div>
  {/if}

  <!-- Online Users List -->
  {#if users.length > 0}
    <div class="w-full max-w-2xl p-6">
      <div class="bg-white/10 backdrop-blur-sm rounded-xl p-4 text-white">
        <h3 class="text-lg font-semibold mb-4">Online Players</h3>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
          {#each users as user (user.uuid)}
            <div class="flex items-center space-x-3 p-2 rounded-lg bg-white/5">
              <img
                src={user.avatar_url}
                alt="User avatar"
                class="w-8 h-8 rounded-full"
              />
              <div>
                <p class="font-medium text-sm">{user.name}</p>
                <p class="text-xs opacity-60">{user.uuid.slice(0, 8)}...</p>
              </div>
            </div>
          {/each}
        </div>
      </div>
    </div>
  {/if}
</div>
