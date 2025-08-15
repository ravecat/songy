<script lang="ts" module>
  import { getContext, setContext } from "svelte";
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

  // Context key for game context - using object literal for better testability
  const GAME_CONTEXT_KEY = {};

  export { GAME_CONTEXT_KEY };

  /**
   * Set the game context in Svelte's context system
   *
   * Must be called during component initialization to establish game context
   * for child components. This function is part of the public API.
   *
   * @param context Game context containing state and channel
   */
  export function setGameContext(context: GameContext): void {
    setContext(GAME_CONTEXT_KEY, context);
  }

  /**
   * Get the game context from Svelte's context system
   *
   * Must be called within a component that has a GameContext parent component.
   * Provides access to the current game state and Phoenix channel instance.
   *
   * @returns Game context containing state and channel
   * @throws Error if called outside of a game context
   */
  export function getGameContext(): GameContext {
    const context = getContext<GameContext>(GAME_CONTEXT_KEY);

    if (!context) {
      throw new Error(
        `${getGameContext.name}() must be called within a game context`
      );
    }

    return context;
  }
</script>

<script lang="ts">
  import { useChannel } from "~hooks/useChannel.svelte";
  import socket from "~/socket";
  import type { Snippet } from "svelte";

  interface Props {
    topic: string;
    children?: Snippet;
  }

  let { topic, children }: Props = $props();

  const channel = useChannel({
    socket,
    topic,
    on: {
      state_updated: (newState: Game) => {
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
