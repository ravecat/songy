<script>
  import { getChannelContext } from "@shared/context/channel.js";
  import TrackCard from "@components/TrackCard.svelte";
  import Timeline from "@components/Timeline.svelte";

  const { state } = $derived.by(getChannelContext);
  const track = $derived(state?.turn?.track);

  let timeline = $derived.by(() => {
    return track
      ? [
          {
            id: track.title,
            track: track,
            current: true,
          },
        ]
      : [];
  });
</script>

<Timeline items={timeline} dropFromOthersDisabled={true}>
  {#snippet children(item)}
    <TrackCard revealed={false} track={item.track} />
  {/snippet}
</Timeline>
