<script>
  import { getChannelContext } from "@shared/context/channel.js";
  import Participants from "@components/Participants.svelte";
  import WaitingSlot from "@components/WaitingSlot.svelte";
  import GameButton from "@components/GameButton.svelte";
  import PlayerButton from "@components/PlayerButton.svelte";
  import Spinner from "@components/Spinner.svelte";
  import CurrentTrack from "@components/CurrentTrack.svelte";
  import ParticipantTimeline from "@components/ParticipantTimeline.svelte";

  const { state } = $derived(getChannelContext());

  let isWaiting = $derived(state?.status === "waiting");
  let isProgress = $derived(state?.status === "in_progress");
</script>

<div
  class="min-h-screen flex flex-col justify-center bg-gradient-to-br from-purple-400 via-pink-500 to-red-500"
>
  <div class="mx-auto min-w-[24rem] max-w-[36rem] space-y-2">
    {#if state}
      <Participants />

      {#if isWaiting}
        <WaitingSlot />
      {/if}

      {#if isProgress}
        <PlayerButton />

        <div class="flex items-center justify-center gap-4 py-4">
          <CurrentTrack />
          <ParticipantTimeline />
        </div>
      {/if}
      {#if isWaiting}
        <GameButton />
      {/if}
    {:else}
      <Spinner />
    {/if}
  </div>
</div>
