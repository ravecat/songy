<script lang="ts">
  import type { Snippet } from "svelte";
  import { getGameContext } from "~components/GameChannel.svelte";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();

  let paused = $state(true);
  let currentTime = $state(0);
  let duration = $state(0);

  const { game } = $derived.by(getGameContext);

  const src = $derived(game?.track?.meta?.preview_url);
</script>

<audio
  {src}
  bind:paused
  bind:currentTime
  bind:duration
  onended={() => {
    currentTime = 0;
  }}
></audio>

{@render children?.()}
