import { getContext } from "svelte";
import type { Channel } from "phoenix";
import type { Game } from "~shared/types/game";

/**
 * Channel context interface providing game state and Phoenix channel access
 */
export interface ChannelContext {
  /** Current game state received from the channel */
  state: Game | null;
  /** Phoenix channel instance for real-time communication */
  channel: Channel;
}

/**
 * Get the channel context from Svelte's context system
 * 
 * Must be called within a component that has a Channel parent component.
 * Provides access to the current game state and Phoenix channel instance.
 * 
 * @returns Channel context containing game state and channel
 * @throws Error if called outside of a Channel component
 */
export function getChannelContext(): ChannelContext {
  const context = getContext<ChannelContext>("channel");

  if (!context) {
    throw new Error(
      "getChannelContext() must be called within a Channel component"
    );
  }

  return context;
}
