<script>
  import Scope from "~components/Scope.svelte";
  import socket from "~/socket";
  import GameChannel from "~components/GameChannel.svelte";
  import Room from "~/components/Room.svelte";
  import Spotify from "~components/Spotify.svelte";

  let { roomId } = $props();
</script>

<GameChannel {socket} topic={`room:${roomId}`}>
  <Spotify>
    <Scope>
      <Room />
    </Scope>
  </Spotify>
</GameChannel>
