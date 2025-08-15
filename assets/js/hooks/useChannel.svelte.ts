import type { Socket, Channel, PushStatus } from "phoenix";

/**
 * Join response handlers for channel connection
 * Uses official Phoenix PushStatus types for type safety
 */
type JoinHandlers = {
  [K in PushStatus]?: (response?: any) => any;
};

/**
 * Event handlers map for channel events
 * Uses type extracted from Channel.on method signature
 */
interface EventHandlers {
  [eventName: string]: Parameters<Channel['on']>[1];
}

/**
 * Configuration options for useChannel hook
 */
interface UseChannelOptions {
  /** Phoenix Socket instance */
  socket: Socket;
  /** Channel topic string */
  topic: string;
  /** Optional payload for channel join */
  payload?: object | (() => object);
  /** Join response handlers */
  join?: JoinHandlers;
  /** Callback function for channel errors */
  onError?: Parameters<Channel['onError']>[0];
  /** Callback function for channel close */
  onClose?: Parameters<Channel['onClose']>[0];
  /** Event handlers object mapping event names to handlers */
  on?: EventHandlers;
}

/**
 * Hook for Phoenix channel management with automatic cleanup
 * 
 * Provides a convenient way to create, join, and manage Phoenix channels
 * with automatic event handler registration and cleanup on component unmount.
 * 
 * @param options - Channel configuration options
 * @returns Phoenix channel instance
 */
export function useChannel(options: UseChannelOptions): Channel {
  const {
    socket,
    topic,
    payload = {},
    join = {},
    onError = () => {
      console.error(`Channel error on ${topic}, attempting to rejoin...`);
    },
    onClose = () => {
      console.info(`Channel ${topic} closed`);
    },
    on = {},
  } = options;

  const channel = socket.channel(topic, payload);

  const joinCallbacks: Record<PushStatus, (response?: any) => any> = {
    ok: (resp?: any) => {
      console.info(`Joined ${topic} successfully`, resp);
      return join.ok?.(resp);
    },
    error: (resp?: any) => {
      console.info(`Unable to join ${topic}`, resp);
      return join.error?.(resp);
    },
    timeout: () => {
      console.info(`Networking issue with ${topic}`);
      return join.timeout?.();
    },
  };

  Object.entries(on).forEach(([eventName, handler]) => {
    channel.on(eventName, handler);
  });

  channel
    .join()
    .receive("ok", joinCallbacks.ok)
    .receive("error", joinCallbacks.error)
    .receive("timeout", joinCallbacks.timeout);


  channel.onError(onError);
  channel.onClose(onClose);

  $effect(() => {
    return () => {
      channel.leave();
    };
  });

  return channel;
}
