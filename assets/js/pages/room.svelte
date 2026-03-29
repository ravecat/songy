<script module>
  export { default as layout } from "~/layout.svelte";
</script>

<script lang="ts">
  import socket from "~/socket";
  import GameProvider from "~components/game_provider.svelte";
  import Room from "~components/room.svelte";

  interface Props {
    roomId: string;
  }

  let { roomId }: Props = $props();
</script>

<GameProvider {socket} topic={`room:${roomId}`}>
  <Room />
</GameProvider>
