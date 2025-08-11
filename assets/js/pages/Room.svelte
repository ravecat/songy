<script>
  import Scope from "@components/Scope.svelte";
  import Channel from "@components/Channel.svelte";
  import RoomView from "@components/RoomView.svelte";
  import Spotify from "@components/Spotify.svelte";

  let { roomId } = $props();
</script>

<Channel topic={`room:${roomId}`}>
  <Spotify>
    <Scope>
      <RoomView />
    </Scope>
  </Spotify>
</Channel>
