<script lang="ts">
  import { getChannelContext } from "~shared/context/channel";
  import TrackCard from "~components/TrackCard.svelte";
  import Timeline from "~components/Timeline.svelte";

  const { state } = $derived.by(getChannelContext);
  const track = $derived(state?.turn?.track);

  let timeline = $derived.by(() => {
    return track
      ? [
          {
            id: track.id,
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
