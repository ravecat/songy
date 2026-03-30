<script lang="ts">
  import GameProvider from "~components/game_provider.svelte";
  import Timer from "~components/timer.svelte";

  interface Props {
    topic: string;
  }

  let { topic }: Props = $props();
</script>

<GameProvider {topic}>
  <Timer />
</GameProvider>
