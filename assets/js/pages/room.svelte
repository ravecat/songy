<script module>
  export { default as layout } from "~/layout.svelte";
</script>

<script lang="ts">
  import GameProvider from "~components/game_provider.svelte";
  import MediaProvider from "~components/media_provider.svelte";
  import { provider } from "~/stores/scope";
  import Room from "~components/room.svelte";

  interface Props {
    roomId: string;
  }

  let { roomId }: Props = $props();
</script>

<GameProvider topic={`room:${roomId}`}>
  <MediaProvider provider={$provider}>
    <Room />
  </MediaProvider>
</GameProvider>
