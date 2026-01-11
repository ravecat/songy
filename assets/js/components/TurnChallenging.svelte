<script lang="ts">
  import ActiveTimeline from "~components/ActiveTimeline.svelte";
  import Timer from "~components/Timer.svelte";
  import CurrentTrack from "~components/CurrentTrack.svelte";
  import { getGameContext } from "~components/GameChannel.svelte";
  import { BROADCAST_EVENT } from "~shared/types/channel";

  const { channel } = $derived.by(getGameContext);
  let seconds = $state<number | null>(null);

  $effect(() => {
    const ref = channel.on(BROADCAST_EVENT.TIMER, ({ remaining }) => {
      seconds = remaining;
    });

    return () => {
      channel.off(BROADCAST_EVENT.TIMER, ref);
    };
  });
</script>

<div class="relative flex min-h-0 flex-1 flex-col">
  <Timer {seconds} />
  <div class="flex min-h-0 flex-1">
    <ActiveTimeline />
  </div>
  <div class="shrink-0">
    <CurrentTrack />
  </div>
</div>
