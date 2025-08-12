<script>
  import { slide } from "svelte/transition";
  import { getChannelContext } from "~shared/context/channel";

  const { state } = $derived(getChannelContext());

  let userCount = $derived(state?.participants?.length ?? 0);
</script>

<div
  in:slide={{ duration: 400, axis: "y" }}
  out:slide={{ duration: 400, axis: "y" }}
>
  {#each Array(state.max_participants - userCount) as _, index}
    <div
      class="flex items-center p-2 bg-white/10 backdrop-blur-sm rounded-lg border-2 border-dashed border-white/30 mb-2"
    >
      <div
        class="w-16 h-16 rounded-lg bg-white/10 flex-shrink-0 flex items-center justify-center"
      >
        <div class="text-2xl text-white/50 font-bold">?</div>
      </div>
      <div class="ml-4 text-left">
        <div class="text-lg font-medium text-white/50">Waiting for player</div>
      </div>
    </div>
  {/each}
</div>
