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
    display: flex;
    flex-direction: column;
    justify-content: center;
    min-height: 100vh;
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
