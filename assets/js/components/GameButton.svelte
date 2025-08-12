<script>
  import { slide, fly } from "svelte/transition";
  import { getChannelContext } from "~shared/context/channel";

  const { channel } = $derived(getChannelContext());
  let isLoading = $state(false);

  const handleStartGame = () => {
    isLoading = true;

    channel
      .push("start_game", {})
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
      <div
        class="w-5 h-5 border-2 border-purple-600 border-t-transparent rounded-full animate-spin"
      ></div>
      <span>Starting...</span>
    </div>
  {:else}
    Start
  {/if}
</button>
