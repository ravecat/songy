<script>
  import { setContext } from "svelte";
  import { useChannel } from "@hooks/useChannel.svelte";
  import socket from "@/socket";

  let { topic, children } = $props();
  let context = $state({ state: null, channel: null });

  const channel = useChannel({
    socket,
    topic,
    on: {
      state_updated: (newState) => {
        context.state = newState;
      },
    },
  });

  $effect.pre(() => {
    context.channel = channel;
  });

  setContext("channel", context);
</script>

{@render children()}
