import type {
  Channel,
  Push,
  PushStatus,
  Socket,
} from "phoenix";

type EmptyPayload = Record<string, never>;

export type TransportPushEventSpec = {
  payload?: object;
  reply?: Partial<Record<PushStatus, unknown>>;
};

export interface TransportSpec {
  on: Record<string, unknown>;
  push: Record<string, TransportPushEventSpec>;
  join?: Partial<Record<PushStatus, unknown>>;
}

type PushPayload<TEvent extends TransportPushEventSpec> =
  TEvent extends { payload: infer TPayload extends object }
  ? TPayload
  : EmptyPayload;

type PushReplies<TEvent extends TransportPushEventSpec> =
  TEvent extends {
    reply: infer TReply extends Partial<Record<PushStatus, unknown>>;
  }
  ? TReply
  : Record<never, never>;

type JoinReplies<TSpec extends TransportSpec> =
  TSpec extends { join: infer TReply extends Partial<Record<PushStatus, unknown>> }
  ? TReply
  : Record<never, never>;

type ReplyPayload<
  TReplies extends Partial<Record<PushStatus, unknown>>,
  TStatus extends PushStatus,
> =
  TStatus extends Extract<keyof TReplies, PushStatus>
  ? TReplies[TStatus]
  : unknown;

type TypedPush<TEvent extends TransportPushEventSpec> = Omit<
  Push,
  "receive"
> & {
  receive<TStatus extends PushStatus>(
    status: TStatus,
    callback: (
      response: TStatus extends Extract<keyof PushReplies<TEvent>, PushStatus>
        ? PushReplies<TEvent>[TStatus]
        : unknown,
    ) => void,
  ): TypedPush<TEvent>;
};

type TypedChannel<TSpec extends TransportSpec> = Omit<
  Channel,
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
  join(): TypedPush<{ reply: JoinReplies<TSpec> }>;
};

export type TransportReplyResult<
  TReplies extends Partial<Record<PushStatus, unknown>>,
> =
  | {
    status: "ok";
    response: ReplyPayload<TReplies, "ok">;
  }
  | {
    status: "error";
    response: ReplyPayload<TReplies, "error">;
  }
  | {
    status: "timeout";
  };

export type TransportStatus =
  | "idle"
  | "joining"
  | "active"
  | "failed"
  | "closed";

export type TransportFailure =
  | {
    kind: "error";
    error: unknown;
  }
  | {
    kind: "close";
  };

export interface Transport<TSpec extends TransportSpec> {
  readonly status: TransportStatus;
  join(): Promise<TransportReplyResult<JoinReplies<TSpec>>>;
  onFailure(callback: (failure: TransportFailure) => void): () => void;
  subscribe<TEvent extends keyof TSpec["on"] & string>(
    event: TEvent,
    callback: (payload: TSpec["on"][TEvent]) => void,
  ): () => void;
  push<TEvent extends keyof TSpec["push"] & string>(
    event: TEvent,
    payload: PushPayload<TSpec["push"][TEvent]>,
    timeout?: number,
  ): Promise<TransportReplyResult<PushReplies<TSpec["push"][TEvent]>>>;
  dispose(): void;
}

interface TransportOptions {
  socket: Socket;
  topic: string;
  payload?: object;
  onError?: Parameters<Channel["onError"]>[0];
  onClose?: Parameters<Channel["onClose"]>[0];
}

function waitForReply<TReplies extends Partial<Record<PushStatus, unknown>>>(
  push: TypedPush<{ reply: TReplies }>,
  lifecycle?: Partial<{
    ok: (response: ReplyPayload<TReplies, "ok">) => void;
    error: (response: ReplyPayload<TReplies, "error">) => void;
    timeout: () => void;
  }>,
) {
  return new Promise<TransportReplyResult<TReplies>>((resolve) => {
    push.receive("ok", (response) => {
      lifecycle?.ok?.(response as ReplyPayload<TReplies, "ok">);
      resolve({
        status: "ok",
        response: response as ReplyPayload<TReplies, "ok">,
      });
    });

    push.receive("error", (response) => {
      lifecycle?.error?.(response as ReplyPayload<TReplies, "error">);
      resolve({
        status: "error",
        response: response as ReplyPayload<TReplies, "error">,
      });
    });

    push.receive("timeout", () => {
      lifecycle?.timeout?.();
      resolve({ status: "timeout" });
    });
  });
}

const transportTransitions: Record<TransportStatus, readonly TransportStatus[]> = {
  idle: ["joining", "failed", "closed"],
  joining: ["active", "failed", "closed"],
  active: ["failed", "closed"],
  failed: ["active", "failed", "closed"],
  closed: [],
};

export function createTransport<TSpec extends TransportSpec>(
  options: TransportOptions,
): Transport<TSpec> {
  const channel = options.socket.channel(
    options.topic,
    options.payload ?? {},
  ) as TypedChannel<TSpec>;
  const failureSubscribers = new Set<
    (failure: TransportFailure) => void
  >();
  let status: TransportStatus = "idle";

  function notifyFailure(failure: TransportFailure) {
    for (const subscriber of failureSubscribers) {
      subscriber(failure);
    }
  }

  function transitionTo(nextStatus: TransportStatus) {
    if (status === nextStatus) {
      return;
    }

    if (!transportTransitions[status].includes(nextStatus)) {
      throw new Error(
        `Transport cannot transition from ${status} to ${nextStatus}`,
      );
    }

    status = nextStatus;
  }

  function assertNotClosed(operation: string) {
    if (status === "closed") {
      throw new Error(`Transport cannot ${operation} while closed`);
    }
  }

  function assertPushable() {
    assertNotClosed("push");

    if (status === "idle") {
      throw new Error("Transport cannot push before join");
    }
  }

  function bindLifecycleHandlers() {
    channel.onError((error) => {
      const active = status !== "closed";

      if (active) {
        transitionTo("failed");
        notifyFailure({
          kind: "error",
          error,
        });
      }

      options.onError?.(error);
    });

    channel.onClose((payload, ref, joinRef) => {
      const active = status !== "closed";

      if (active) {
        transitionTo("failed");
        notifyFailure({ kind: "close" });
      }

      options.onClose?.(payload, ref, joinRef);
    });
  }

  bindLifecycleHandlers();

  return {
    get status() {
      return status;
    },

    onFailure(callback) {
      assertNotClosed("subscribe to failures");
      failureSubscribers.add(callback);

      return () => {
        failureSubscribers.delete(callback);
      };
    },

    subscribe(event, callback) {
      assertNotClosed("subscribe");

      const ref = channel.on(event, callback);

      return () => {
        if (status === "closed") {
          return;
        }

        channel.off(event, ref);
      };
    },

    join() {
      assertNotClosed("join");

      if (status !== "idle") {
        throw new Error(`Transport cannot join while ${status}`);
      }

      transitionTo("joining");
      const push = channel.join() as TypedPush<{ reply: JoinReplies<TSpec> }>;

      return waitForReply(
        push,
        {
          ok: () => {
            transitionTo("active");
          },
          error: () => {
            transitionTo("failed");
          },
          timeout: () => {
            transitionTo("failed");
          },
        },
      );
    },

    push<TEvent extends keyof TSpec["push"] & string>(
      event: TEvent,
      payload: PushPayload<TSpec["push"][TEvent]>,
      timeout?: number,
    ): Promise<TransportReplyResult<PushReplies<TSpec["push"][TEvent]>>> {
      assertPushable();

      return waitForReply(
        channel.push(event, payload, timeout) as TypedPush<{
          reply: PushReplies<TSpec["push"][TEvent]>;
        }>,
      );
    },

    dispose() {
      if (status === "closed") {
        return;
      }

      transitionTo("closed");
      channel.leave();
    },
  };
}
