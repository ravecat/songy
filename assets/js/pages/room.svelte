<script>
  import Scope from "~components/Scope.svelte";
  import socket from "~/socket";
  import GameChannel from "~components/GameChannel.svelte";
  import Room from "~/components/Room.svelte";
  import MediaProvider from "~components/MediaProvider.svelte";
  import QrContext from "~components/QrContext.svelte";

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
