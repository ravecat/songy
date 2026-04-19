<script lang="ts">
  import { getGameContext } from "~/contexts/game";
  import { currentUser } from "~/stores/scope";

  const session = getGameContext();
  const game = $derived($session.snapshot?.game ?? null);
  const activePlayer = $derived(game!.participants[game!.queue[game!.cursor]]);
  const isCurrentUserActive = $derived(activePlayer?.id === $currentUser?.id);
</script>

<div class="turn-waiting" role="region" aria-label="Turn waiting">
  <div class="turn-waiting__player">
    <div class="turn-waiting__avatar avatar">
      <div
        class="ring-primary ring-offset-base-100 w-16 rounded-full ring-2 ring-offset-2"
      >
        <img src={activePlayer.avatar_url} alt={activePlayer.name} />
      </div>
    </div>
    <h2 class="turn-waiting__title">
      {isCurrentUserActive ? "It's your turn" : `${activePlayer.name} turn`}
    </h2>
  </div>
</div>

<style>
  .turn-waiting {
    display: flex;
    justify-content: center;
    align-items: center;
    text-align: center;
    width: 100%;
    min-height: 100%;
  }

  .turn-waiting__title {
    color: #333;
    font-size: 1.5rem;
  }
</style>
