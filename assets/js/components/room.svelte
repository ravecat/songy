<script>
  import { getGameContext } from "~/contexts/game";
  import Game from "~components/game.svelte";
  import Equalizer from "~components/equalizer.svelte";
  import Player from "~components/player.svelte";
  import Participants from "~components/participants.svelte";
  import Score from "~components/score.svelte";
  import Timer from "~components/timer.svelte";

  const session = $derived.by(getGameContext);
  const game = $derived(session.snapshot?.game ?? null);
</script>

<div class="room">
  {#if !game}
    <Equalizer />
  {:else}
    <main class="room__content">
      <div class="room__header">
        <Timer />
        <div class="room__header-actions">
          <Score />
          <Participants />
        </div>
      </div>
      <Game />
      <Player />
    </main>
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
