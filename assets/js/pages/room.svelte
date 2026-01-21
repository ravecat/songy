<script>
  import Scope from "~components/Scope.svelte";
  import socket from "~/socket";
  import GameChannel from "~components/GameChannel.svelte";
  import Room from "~/components/Room.svelte";
  import AudioPlayer from "~components/AudioPlayer.svelte";
  import Spotify from "~components/Spotify.svelte";
  import { Provider } from "~shared/types/provider";

  let { roomId, provider } = $props();
</script>

<GameChannel {socket} topic={`room:${roomId}`}>
  {#if provider === Provider.SPOTIFY}
    <Spotify>
      <Scope>
        <Room />
      </Scope>
    </Spotify>
  {:else if provider === Provider.ITUNES || provider === Provider.APPLE}
    <AudioPlayer>
      <Scope>
        <Room />
      </Scope>
    </AudioPlayer>
  {:else}
    <Scope>
      <Room />
    </Scope>
  {/if}
</GameChannel>
