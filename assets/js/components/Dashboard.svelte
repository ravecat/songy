<script>
  import { slide } from "svelte/transition";
  import { getChannelContext } from "@shared/context/channel.js";
  import Participant from "@components/Participant.svelte";
  import WaitingSlot from "@components/WaitingSlot.svelte";
  import GameButton from "@components/GameButton.svelte";
  import PlayerButton from "@components/PlayerButton.svelte";

  const { state, channel } = $derived(getChannelContext());

  let userCount = $derived(state?.participants?.length ?? 0);
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

        <!-- Control Buttons -->
        {#if state.status === "waiting"}
          <GameButton />
        {:else if state.status === "in_progress"}
          <PlayerButton />
        {/if}
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
