<script>
  import { Modals } from "svelte-modals";
  import Scope from "@components/Scope.svelte";
  import Channel from "@components/Channel.svelte";
  import GameView from "@components/GameView.svelte";
  import Spotify from "@components/Spotify.svelte";

  let { roomId } = $props();
</script>

<Channel topic={`room:${roomId}`}>
  <Spotify>
    <Scope>
      <GameView />
    </Scope>
  </Spotify>
</Channel>
<Modals />
