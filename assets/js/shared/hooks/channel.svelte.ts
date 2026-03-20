import { untrack } from "svelte";
import type { Channel, PushStatus, Socket } from "phoenix";

export interface UseChannelOptions {
  socket: Socket;
  topic: Parameters<Socket["channel"]>[0];
  payload?: Parameters<Socket["channel"]>[1];
  on?: Record<string, (payload: any) => void>;
  join?: Partial<Record<PushStatus, (response?: any) => void>>;
  onError?: Parameters<Channel["onError"]>[0];
  onClose?: Parameters<Channel["onClose"]>[0];
}

export function useChannel(options: UseChannelOptions): Channel {
  const channel = untrack(() => {
    const ch = options.socket.channel(options.topic, options.payload ?? {});

    for (const [event, handler] of Object.entries(options.on ?? {})) {
      ch.on(event, handler);
    }

    const push = ch.join();

    for (const [status, handler] of Object.entries(options.join ?? {})) {
      if (handler) push.receive(status as PushStatus, handler);
    }

    ch.onError(
      options.onError ?? (() => console.error(`Channel error on ${options.topic}`)),
    );
    ch.onClose(
      options.onClose ?? (() => console.info(`Channel ${options.topic} closed`)),
    );

    return ch;
  });

  $effect(() => {
    return () => {
      channel.leave();
    };
  });

  return channel;
}
