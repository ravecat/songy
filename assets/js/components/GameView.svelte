<script>
  import { getChannelContext } from "@shared/context/channel.js";
  import Lobby from "@components/Lobby.svelte";
  import Game from "@components/Game.svelte";
  import Spinner from "@components/Spinner.svelte";

  const { state } = $derived(getChannelContext());

  let isWaiting = $derived(state?.status === "waiting");
</script>

<div
  class="min-h-screen flex flex-col justify-center bg-gradient-to-br from-purple-400 via-pink-500 to-red-500"
>
  <div class="mx-auto min-w-[24rem] max-w-[36rem] space-y-2">
    {#if state}
      {#if isWaiting}
        <Lobby />
      {:else}
        <Game />
      {/if}
    {:else}
      <Spinner />
    {/if}
  </div>
</div>
