<script>
  import Scope from "~components/Scope.svelte";
  import GameContext from "~components/GameContext.svelte";
  import RoomView from "~components/RoomView.svelte";
  import Spotify from "~components/Spotify.svelte";

  let { roomId } = $props();
</script>

<GameContext topic={`room:${roomId}`}>
  <Spotify>
    <Scope>
      <RoomView />
    </Scope>
  </Spotify>
</GameContext>
