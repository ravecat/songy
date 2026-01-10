<script lang="ts" module>
  import { createContext } from "svelte";
  import type { Channel } from "phoenix";
  import type { Game } from "~shared/types/game";
  import type { Permissions } from "~shared/types/permissions";

  /**
   * Game context interface providing game state and Phoenix channel access
   */
  export interface GameContext {
    /** Current game received from the channel */
    game: Game | null;
    /** User permissions for the current game, computed on the server */
    permissions: Permissions | null;
    /** Phoenix channel instance for real-time communication */
    channel: Channel;
  }

  export const [getGameContext, setGameContext] = createContext<GameContext>();
</script>

<script lang="ts">
  import { useChannel, type ChannelProps } from "~components/Channel.svelte";
  import { BROADCAST_EVENT } from "~shared/types/channel";
  import type { Snippet } from "svelte";

  let { children, ...rest }: ChannelProps & { children?: Snippet } = $props();

  const { channel } = useChannel(rest);

  let context = $state<GameContext>({
    game: null,
    permissions: null,
    channel,
  });

  channel.on(
    BROADCAST_EVENT.STATE,
    (response: { game: Game; permissions: Permissions }) => {
      context.game = response.game;
      context.permissions = response.permissions;
    }
  );

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
