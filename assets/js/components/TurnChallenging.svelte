<script lang="ts">
  import ScrollableTimeline from "~components/ScrollableTimeline.svelte";
  import Timer from "~components/Timer.svelte";
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

<Timer {seconds} />
<ScrollableTimeline />
