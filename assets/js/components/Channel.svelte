<script lang="ts" module>
  import { createContext } from "svelte";
  import type { Channel, Socket } from "phoenix";
  import type { Snippet } from "svelte";

  /**
   * Context containing Phoenix channel instance
   * Provides access to channel for sending/receiving messages
   */
  export interface ChannelContext {
    /** Phoenix channel instance for direct access */
    channel: Channel;
  }

  /**
   * Props for the Channel component
   * API mirrors Phoenix channel/socket library naming conventions
   */
  export interface ChannelProps {
    /** Phoenix Socket instance */
    socket: Socket;
    /** Channel topic string (e.g., "game:123", "room:lobby") */
    topic: string;
    /** Parameters to send on channel join (auth tokens, user data, etc.) */
    payload?: object;
    /** Event handlers - maps event names to callbacks */
    on?: Record<string, (payload: any) => void>;
    /** Join response handlers matching channel.join().receive() API */
    join?: {
      ok?: (response?: any) => void;
      error?: (reason?: any) => void;
      timeout?: () => void;
    };
    /** Callback function for channel errors */
    onError?: Parameters<Channel["onError"]>[0];
    /** Callback function for channel close */
    onClose?: Parameters<Channel["onClose"]>[0];
  }

  export function useChannel({
    socket,
    topic,
    payload = {},
    on = {},
    join = {},
    onError = () => console.error(`Channel error on ${topic}`),
    onClose = () => console.info(`Channel ${topic} closed`),
  }: ChannelProps) {
    const channel = socket.channel(topic, payload);

    Object.entries(on).forEach(([eventName, handler]) => {
      channel.on(eventName, handler);
    });

    channel
      .join()
      .receive("ok", (resp) => {
        console.info(`✓ Joined ${topic}`, resp);
        join.ok?.(resp);
      })
      .receive("error", (resp) => {
        console.error(`✗ Failed to join ${topic}`, resp);
        join.error?.(resp);
      })
      .receive("timeout", () => {
        console.warn(`⏱ Timeout joining ${topic}`);
        join.timeout?.();
      });

    channel.onError(onError);
    channel.onClose(onClose);

    return { channel };
  }

  /**
   * Create context for channel - exported for use in child components
   * Usage: const { channel } = $derived.by(getChannelContext);
   */
  export const [getChannelContext, setChannelContext] =
    createContext<ChannelContext>();
</script>

<script lang="ts">
  import { untrack } from "svelte";

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

  const { channel } = untrack(() =>
    useChannel({
      socket,
      topic,
      payload,
      on,
      join,
      onError,
      onClose,
    })
  );

  // Make context available to child components
  setChannelContext({ channel });

  $effect(() => {
    return () => {
      channel.leave();
    };
  });
</script>

{@render children?.()}
