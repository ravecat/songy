<script>
  import Scope from "~components/scope.svelte";
  import socket from "~/socket";
  import GameChannel from "~components/game_channel.svelte";
  import Room from "~components/room.svelte";
  import MediaProvider from "~components/media_provider.svelte";
  import QrContext from "~components/qr_context.svelte";

  let { roomId, provider, qrSvg } = $props();
</script>

<GameChannel {socket} topic={`room:${roomId}`}>
  <MediaProvider {provider}>
    <QrContext svg={qrSvg}>
      <Scope>
        <Room />
      </Scope>
    </QrContext>
  </MediaProvider>
</GameChannel>
