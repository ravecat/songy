<script>
  import { getGameContext } from "~components/GameChannel.svelte";
  import Game from "~components/Game.svelte";
  import Logo from "~components/Logo.svelte";
  import Player from "~components/Player.svelte";
  import Participants from "~components/Participants.svelte";
  import GameButton from "~components/GameButton.svelte";

  const { game } = $derived.by(getGameContext);

  let isWaiting = $derived(game?.status === "waiting");
</script>

<div
  class="flex min-h-screen flex-col bg-[rgba(75,179,153,1)] bg-[radial-gradient(circle_at_center,_rgba(75,179,153,1),_rgba(44,94,167,1))]"
>
  <Logo loading={!game}>
    <Participants />
    <div class="flex flex-1 items-center justify-center">
      {#if isWaiting}
        <GameButton />
      {:else}
        <Game />
      {/if}
    </div>
    <Player />
  </Logo>
</div>
