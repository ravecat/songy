<script lang="ts" module>
  import { createContext } from "svelte";
  import type { Channel } from "phoenix";
  import type { Game } from "~shared/types/game";

  /**
   * Game context interface providing game state and Phoenix channel access
   */
  export interface GameContext {
    /** Current game state received from the channel */
    state: Game | null;
    /** Phoenix channel instance for real-time communication */
    channel: Channel;
  }

  export const [getGameContext, setGameContext] = createContext<GameContext>();
</script>

<script lang="ts">
  import { useChannel, type ChannelProps } from "~components/Channel.svelte";
  import { BROADCAST_EVENT } from "~shared/types/channel";
  import type { Snippet } from "svelte";

  let {
    socket,
    topic,
    payload,
    on,
    join,
    onError,
    onClose,
    children,
  }: ChannelProps & { children?: Snippet } = $props();

  const { channel } = useChannel({
    socket,
    topic,
    payload,
    on,
    join,
    onError,
    onClose,
  });

  // Create game context with channel
  let context = $state<GameContext>({
    state: null,
    channel,
  });

  // Register event handler for state updates
  channel.on(BROADCAST_EVENT.STATE_UPDATED, (response: Game) => {
    context.state = response;
  });

  // Make context available to child components
  setGameContext(context);

  // Cleanup when component unmounts
  $effect(() => {
    return () => {
      channel.leave();
    };
  });
</script>

{@render children?.()}
