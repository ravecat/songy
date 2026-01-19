<script>
  import { getGameContext } from "~components/GameChannel.svelte";
  import Game from "~components/Game.svelte";
  import Logo from "~components/Logo.svelte";
  import Player from "~components/Player.svelte";
  import Participants from "~components/Participants.svelte";
  import Score from "~components/Score.svelte";
  import Timer from "~components/Timer.svelte";

  const { game } = $derived.by(getGameContext);
</script>

<div class="room">
  {#if !game}
    <Logo />
  {:else}
    <div class="content">
      <div class="header-container">
        <Timer />
        <div class="header-right">
          <Score />
          <Participants />
        </div>
      </div>
      <Game />
      <Player />
    </div>
  {/if}
</div>

<style>
  .room {
    width: 100%;
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background-image: var(--landing-gradient);
  }

  .content {
    height: 100%;
    width: 100%;
    display: grid;
    grid-template-rows: auto minmax(0, 1fr) auto;
  }

  .header-container {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
  }

  .header-right {
    display: flex;
    gap: 1rem;
    margin-left: auto;
  }
</style>
