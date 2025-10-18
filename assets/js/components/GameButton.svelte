<script>
  import { slide, fly } from "svelte/transition";
  import { getGameContext } from "~components/GameContext.svelte";
  import { PUSH_EVENT } from "~/shared/types/channel";

  const { channel } = $derived.by(getGameContext);
  let isLoading = $state(false);

  const handleStartGame = () => {
    isLoading = true;

    channel
      .push(PUSH_EVENT.START_GAME, {})
      .receive("ok", () => {
        isLoading = false;
      })
      .receive("error", () => {
        isLoading = false;
      });
  };
</script>

<button
  in:slide={{ duration: 400 }}
  out:fly={{ y: 400, duration: 400 }}
  class="btn w-full"
  onclick={handleStartGame}
  disabled={isLoading}
>
  {#if isLoading}
    <div class="flex items-center justify-center space-x-2">
      <span class="loading loading-spinner"></span>
      <span>Starting...</span>
    </div>
  {:else}
    Start
  {/if}
</button>
