<script>
  import { getGameContext } from "~components/GameChannel.svelte";
  import Game from "~components/Game.svelte";
  import Equalizer from "~components/Equalizer.svelte";
  import Player from "~components/Player.svelte";
  import Participants from "~components/Participants.svelte";
  import Score from "~components/Score.svelte";
  import Timer from "~components/Timer.svelte";

  const { game } = $derived.by(getGameContext);
</script>

<div class="room">
  {#if !game}
    <Equalizer />
  {:else}
    <div class="room__content" role="main" aria-label="Game room">
      <div class="room__header">
        <Timer />
        <div class="room__header-actions">
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
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .room__content {
    height: 100%;
    width: 100%;
    display: grid;
    grid-template-rows: auto minmax(0, 1fr) auto;
  }

  .room__header {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
  }

  .room__header-actions {
    display: flex;
    gap: 1rem;
    margin-left: auto;
  }
</style>
