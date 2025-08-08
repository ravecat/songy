<script>
  import Scope from "@components/Scope.svelte";
  import Channel from "@components/Channel.svelte";
  import GameView from "@components/GameView.svelte";
  import Spotify from "@components/Spotify.svelte";
  import Background from "@components/Background.svelte";

  let { roomId } = $props();
</script>

<Channel topic={`room:${roomId}`}>
  <Spotify>
    <Scope>
      <Background>
        <GameView />
      </Background>
    </Scope>
  </Spotify>
</Channel>
