<script lang="ts">
  import type { Socket } from "phoenix";
  import GameProvider from "~components/game_provider.svelte";
  import Timer from "~components/timer.svelte";

  interface Props {
    socket: Socket;
    topic: string;
  }

  let { socket, topic }: Props = $props();
</script>

<GameProvider {socket} {topic}>
  <Timer />
</GameProvider>
