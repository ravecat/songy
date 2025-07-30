<script>
  import Scope from "@/components/Scope.svelte";
  import Channel from "@components/Channel.svelte";
  import Dashboard from "@components/Dashboard.svelte";
  import Spotify from "@components/Spotify.svelte";

  let { roomId } = $props();
</script>

<Channel topic={`room:${roomId}`}>
  <Spotify>
    <Scope>
      <Dashboard />
    </Scope>
  </Spotify>
</Channel>
