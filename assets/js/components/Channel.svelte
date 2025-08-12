<script lang="ts">
  import { setContext } from "svelte";
  import { useChannel } from "~hooks/useChannel.svelte";
  import socket from "~/socket";
  import type { Channel } from "phoenix";
  import type { Game } from "~shared/types/game";
  import type { ChannelContext } from "~shared/context/channel";
  import type { Snippet } from "svelte";

  interface Props {
    topic: string;
    children?: Snippet;
  }

  let { topic, children }: Props = $props();
  let context = $state<ChannelContext>({
    state: null,
    channel: null,
  });

  const channel = useChannel({
    socket,
    topic,
    on: {
      state_updated: (newState: Game) => {
        context.state = newState;
      },
    },
  });

  // Prepare channel context before rendering children
  $effect.pre(() => {
    context.channel = channel;
  });

  setContext("channel", context);
</script>

{@render children?.()}
