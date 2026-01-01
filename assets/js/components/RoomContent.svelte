<script>
  import { getGameContext } from "~components/GameChannel.svelte";
  import Lobby from "~components/Lobby.svelte";
  import Game from "~components/Game.svelte";
  import Logo from "~components/Logo.svelte";

  const { game } = $derived.by(getGameContext);
  let isWaiting = $derived(game?.status === "waiting");
</script>

<div class="wrapper">
  <div class="content">
    <Logo loading={!game}>
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
    min-width: 100vw;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(75, 179, 153, 1);
    background: radial-gradient(
      at center,
      rgba(75, 179, 153, 1),
      rgba(44, 94, 167, 1)
    );
  }

  .content {
    margin: 0 auto;
    min-width: 24rem;
    max-width: 36rem;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    position: relative;
    z-index: 1;
  }
</style>
