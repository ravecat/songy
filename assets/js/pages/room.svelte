<script>
  import Scope from "~components/Scope.svelte";
  import socket from "~/socket";
  import GameChannel from "~components/GameChannel.svelte";
  import Room from "~/components/Room.svelte";
  import MediaProvider from "~components/MediaProvider.svelte";

  let { roomId, provider } = $props();
</script>

<GameChannel {socket} topic={`room:${roomId}`}>
  <MediaProvider {provider}>
    <Scope>
      <Room />
    </Scope>
  </MediaProvider>
</GameChannel>
