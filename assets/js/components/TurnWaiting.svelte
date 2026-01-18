<script lang="ts">
  import { getGameContext } from "~components/GameChannel.svelte";
  import Logo from "~components/Logo.svelte";

  const { game, permissions } = $derived.by(getGameContext);

  const activePlayer = $derived.by(() => {
    const activePlayerUuid = game?.queue?.[game?.cursor];
    return game?.participants?.find(({ uuid }) => uuid === activePlayerUuid);
  });
</script>

<div class="turn-waiting-screen">
  {#if !activePlayer}
    <Logo />
  {:else}
    <div class="player-info">
      <div class="avatar">
        <div
          class="ring-primary ring-offset-base-100 w-16 rounded-full ring-2 ring-offset-2"
        >
          <img src={activePlayer.avatar_url} alt={activePlayer.name} />
        </div>
      </div>
      <h2>
        {permissions?.can_start_turn
          ? "It's your turn"
          : `${activePlayer.name} turn`}
      </h2>
    </div>
  {/if}
</div>

<style>
  .turn-waiting-screen {
    display: flex;
    justify-content: center;
    align-items: center;
    text-align: center;
  }

  h2 {
    color: #333;
    font-size: 1.5rem;
  }
</style>
