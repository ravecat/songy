<script>
  import { slide } from "svelte/transition";
  import { getChannelContext } from "@shared/context/channel.js";

  const { state } = $derived(getChannelContext());
</script>

{#if state.participants && state.participants.length > 0}
  {#each state.participants as participant}
    <div
      in:slide={{ duration: 400, axis: "y" }}
      out:slide={{ duration: 400, axis: "y" }}
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
