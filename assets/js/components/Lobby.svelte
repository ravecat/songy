<script>
  import { getChannelContext } from "@shared/context/channel.js";
  import Participants from "@components/Participants.svelte";
  import WaitingSlot from "@components/WaitingSlot.svelte";
  import GameButton from "@components/GameButton.svelte";
  import Spinner from "@components/Spinner.svelte";

  const { state } = $derived(getChannelContext());
</script>

<div class="mx-auto min-w-[24rem] max-w-[36rem] space-y-2">
  {#if state}
    <Participants />
    <WaitingSlot />
    <GameButton />
  {:else}
    <Spinner />
  {/if}
</div>
