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
  import { useChannel } from "~hooks/useChannel.svelte";
  import socket from "~/socket";
  import type { Snippet } from "svelte";
  import { BROADCAST_EVENT } from "~shared/types/channel";

  interface Props {
    topic: string;
    children?: Snippet;
  }

  let { topic, children }: Props = $props();

  const channel = useChannel({
    socket,
    topic,
    on: {
      [BROADCAST_EVENT.STATE_UPDATED]: (newState: Game) => {
        context.state = newState;
      },
    },
  });

  const context = $state<GameContext>({
    state: null,
    channel: channel,
  });

  setGameContext(context);
</script>

{@render children?.()}
