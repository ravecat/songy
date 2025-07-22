<script>
  import socket from "@/socket";
  import Channel from "@components/Channel.svelte";
  import Dashboard from "@components/Dashboard.svelte";

  let { roomId } = $props();
</script>

<Channel topic={`room:${roomId}`}>
  <Dashboard />
</Channel>
