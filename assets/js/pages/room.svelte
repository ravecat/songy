<script>
  import Scope from "~components/scope.svelte";
  import socket from "~/socket";
  import GameProvider from "~components/game_provider.svelte";
  import Room from "~components/room.svelte";
  import MediaProvider from "~components/media_provider.svelte";
  import QrContext from "~components/qr_context.svelte";

  let { roomId, provider, qrSvg } = $props();
</script>

<GameProvider {socket} topic={`room:${roomId}`}>
  <MediaProvider {provider}>
    <QrContext svg={qrSvg}>
      <Scope>
        <Room />
      </Scope>
    </QrContext>
  </MediaProvider>
</GameProvider>
