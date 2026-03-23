import { untrack } from "svelte";
import type {
  Channel as PhoenixChannel,
  Push,
  PushStatus,
  Socket,
} from "phoenix";

type EmptyPayload = Record<string, never>;

type ChannelPushEventSpec = {
  payload?: object;
  reply?: Partial<Record<PushStatus, unknown>>;
};

type ChannelJoinSpec = Partial<Record<PushStatus, unknown>>;

interface ChannelSpec {
  on: Record<string, unknown>;
  push: Record<string, ChannelPushEventSpec>;
  join?: ChannelJoinSpec;
}

type PushPayload<TEvent extends ChannelPushEventSpec> =
  TEvent extends { payload: infer TPayload extends object }
    ? TPayload
    : EmptyPayload;

type PushReplies<TEvent extends ChannelPushEventSpec> =
  TEvent extends {
    reply: infer TReply extends Partial<Record<PushStatus, unknown>>;
  }
  ? TReply
  : never;

type JoinReplies<TSpec extends ChannelSpec> =
  TSpec extends { join: infer TReply extends Partial<Record<PushStatus, unknown>> }
  ? TReply
  : never;

type JoinCallback<TSpec extends ChannelSpec, TStatus extends PushStatus> =
  TStatus extends Extract<keyof JoinReplies<TSpec>, PushStatus>
    ? (response: JoinReplies<TSpec>[TStatus]) => void
    : (response?: unknown) => void;

type TypedPush<TEvent extends ChannelPushEventSpec> = Omit<
  Push,
  "receive"
> & {
  receive<TStatus extends Extract<keyof PushReplies<TEvent>, PushStatus>>(
    status: TStatus,
    callback: (response: PushReplies<TEvent>[TStatus]) => void,
  ): TypedPush<TEvent>;
};

type TypedChannel<TSpec extends ChannelSpec> = Omit<
  PhoenixChannel,
  "push" | "on" | "off"
> & {
  push<TEvent extends keyof TSpec["push"] & string>(
    event: TEvent,
    payload: PushPayload<TSpec["push"][TEvent]>,
    timeout?: number,
  ): TypedPush<TSpec["push"][TEvent]>;
  on<TEvent extends keyof TSpec["on"] & string>(
    event: TEvent,
    callback: (payload: TSpec["on"][TEvent]) => void,
  ): number;
  off<TEvent extends keyof TSpec["on"] & string>(
    event: TEvent,
    ref?: number,
  ): void;
};

declare module "phoenix" {
  interface Socket {
    channel<TSpec extends ChannelSpec>(topic: string, chanParams?: object): TypedChannel<TSpec>;
  }
}

export type Channel<TSpec extends ChannelSpec> = TypedChannel<TSpec>;

interface UseChannelOptions<TSpec extends ChannelSpec> {
  socket: Socket;
  topic: Parameters<Socket["channel"]>[0];
  payload?: Parameters<Socket["channel"]>[1];
  on?: Partial<{
    [TEvent in keyof TSpec["on"] & string]: (
      payload: TSpec["on"][TEvent],
    ) => void;
  }>;
  join?: Partial<{
    [TStatus in PushStatus]: JoinCallback<TSpec, TStatus>;
  }>;
  onError?: Parameters<PhoenixChannel["onError"]>[0];
  onClose?: Parameters<PhoenixChannel["onClose"]>[0];
}

export function useChannel<TSpec extends ChannelSpec>(
  options: UseChannelOptions<TSpec>,
): Channel<TSpec> {
  const channel = untrack(() => {
    const ch = options.socket.channel<TSpec>(options.topic, options.payload ?? {});

    for (const [event, handler] of Object.entries(options.on ?? {})) {
      ch.on(event, handler as Parameters<PhoenixChannel["on"]>[1]);
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
