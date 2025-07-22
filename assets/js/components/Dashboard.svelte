<script>
  import { getChannelContext } from "@shared/context/channel.js";
  import Participant from "@components/Participant.svelte";
  import WaitingSlot from "@components/WaitingSlot.svelte";
  import GameButton from "@components/GameButton.svelte";
  import PlayerButton from "@components/PlayerButton.svelte";
  import Spinner from "@components/Spinner.svelte";
  import TrackCard from "@components/TrackCard.svelte";

  const { state } = $derived(getChannelContext());

  let isWaiting = $derived(state?.status === "waiting");
  let isProgress = $derived(state?.status === "in_progress");
</script>

<div
  class="min-h-screen flex flex-col justify-center bg-gradient-to-br from-purple-400 via-pink-500 to-red-500"
>
  <div class="mx-auto min-w-[24rem] space-y-2">
    {#if state}
      {#if state.participants && state.participants.length > 0}
        {#each state.participants as participant}
          <Participant {participant} />
        {/each}
      {/if}

      {#if isWaiting}
        <WaitingSlot />
      {/if}

      {#if isProgress}
        <PlayerButton />
        <TrackCard />
      {/if}

      {#if isWaiting}
        <GameButton />
      {/if}
    {:else}
      <Spinner />
    {/if}
  </div>
</div>
