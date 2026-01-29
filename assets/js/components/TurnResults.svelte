<script lang="ts">
  import { getGameContext } from "~components/GameChannel.svelte";
  import Vinyl from "~components/Vinyl.svelte";
  import Sleeve from "~components/Sleeve.svelte";

  const { game } = $derived.by(getGameContext);
  const track = $derived(game?.track);
</script>

<div class="results">
  <div class="results__container">
    <div class="results__vinyl">
      <Vinyl {track} />
    </div>
    <div class="results__sleeve">
      <Sleeve {track} />
    </div>
  </div>
</div>

<style>
  .results {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 1.5rem;
    width: 100%;
    height: 100%;
  }

  .results__container {
    position: relative;
    display: flex;
    align-items: center;
  }

  .results__vinyl {
    position: absolute;
    left: 110px;
    width: 200px;
    height: 200px;
    z-index: 0;
  }

  .results__sleeve {
    position: relative;
    z-index: 1;
  }
</style>
