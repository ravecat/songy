<script>
  import { getChannelContext } from "@shared/context/channel.js";
  import Lobby from "@components/Lobby.svelte";
  import Game from "@components/Game.svelte";
  import Logo from "@components/Logo.svelte";

  const { state } = $derived(getChannelContext());

  let isWaiting = $derived(state?.status === "waiting");
</script>

<div class="wrapper">
  <div class="content">
    <Logo loading={!state}>
      {#if isWaiting}
        <Lobby />
      {:else}
        <Game />
      {/if}
    </Logo>
  </div>
</div>

<style>
  .wrapper {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    justify-content: center;
    background: linear-gradient(to bottom right, #c084fc, #ec4899, #ef4444);
  }

  .content {
    margin: 0 auto;
    min-width: 24rem;
    max-width: 36rem;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }
</style>
