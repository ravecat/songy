import type { Readable } from "svelte/store";
import { readable } from "svelte/store";
import socket from "~/transport/socket";

type SessionCommand = (...args: any[]) => void | Promise<unknown>;

interface SessionPush {
  receive(status: string, callback: (payload?: unknown) => void): SessionPush;
}

interface SessionChannel {
  join(timeout?: number): SessionPush;
  leave(timeout?: number): SessionPush;
  on(event: string, callback: (payload?: unknown) => void): number;
  off(event: string, ref?: number): void;
  onError(callback: (error?: unknown) => void): number;
  onClose(
    callback: (payload?: unknown, ref?: unknown, joinRef?: unknown) => void,
  ): number;
  push(event: string, payload: object, timeout?: number): SessionPush;
}

type RuntimeEventReducer = (snapshot: unknown, payload: unknown) => unknown;

type RuntimeCommandConfig = {
  event: string;
  payload: (...args: any[]) => object;
  [status: string]: unknown;
};

const CHANNEL_CLOSE_EVENT = "phx_close";
const CHANNEL_ERROR_EVENT = "phx_error";

export type SessionStatus =
  | "loading"
  | "ready"
  | "stale"
  | "failed";

export interface CommandReply<
  TStatus extends string = string,
  TPayload = unknown,
> {
  status: TStatus;
  payload: TPayload;
}

export type SessionError =
  | {
    kind: "connect_error";
    cause: unknown;
  }
  | {
    kind: "connect_timeout";
    cause?: unknown;
  }
  | {
    kind: "transport_error";
    cause: unknown;
  }
  | {
    kind: "transport_close";
  };

export interface SessionSpec {
  snapshot: unknown;
  connect?: {
    ok?: unknown;
    error?: unknown;
  };
  events: Record<string, unknown>;
  commands: Record<string, SessionCommand>;
}

type SnapshotOf<TSpec extends SessionSpec> = TSpec["snapshot"];

type ConnectOkOf<TSpec extends SessionSpec> =
  TSpec extends { connect: { ok: infer TOk } }
    ? TOk
    : SnapshotOf<TSpec>;

type ConnectErrorOf<TSpec extends SessionSpec> =
  TSpec extends { connect: { error: infer TError } }
    ? TError
    : unknown;

type EventPayloadOf<
  TSpec extends SessionSpec,
  TEvent extends keyof TSpec["events"],
> = TSpec["events"][TEvent];

type CommandArgsOf<
  TSpec extends SessionSpec,
  TCommand extends keyof TSpec["commands"],
> = Parameters<TSpec["commands"][TCommand]>;

type CommandResultOf<
  TSpec extends SessionSpec,
  TCommand extends keyof TSpec["commands"],
> = Awaited<ReturnType<TSpec["commands"][TCommand]>>;

type CommandExpectsReplyOf<
  TSpec extends SessionSpec,
  TCommand extends keyof TSpec["commands"],
> =
  ReturnType<TSpec["commands"][TCommand]> extends Promise<any>
    ? true
    : false;

export interface SessionState<TSnapshot> {
  readonly snapshot: TSnapshot | null;
  readonly status: SessionStatus;
  readonly error: SessionError | null;
}

export interface SessionStore<TSpec extends SessionSpec>
  extends Readable<SessionState<SnapshotOf<TSpec>>> {
  commands: TSpec["commands"];
}

export type ConnectConfig<TSpec extends SessionSpec> = {
  ok?: (
    snapshot: Readonly<SnapshotOf<TSpec>> | null,
    reply: ConnectOkOf<TSpec>,
  ) => SnapshotOf<TSpec>;
  error?: (reply: ConnectErrorOf<TSpec>) => unknown;
  timeout?: () => unknown;
};

export type EventsConfig<TSpec extends SessionSpec> = {
  [K in keyof TSpec["events"]]?: (
    snapshot: Readonly<SnapshotOf<TSpec>>,
    payload: EventPayloadOf<TSpec, K>,
  ) => SnapshotOf<TSpec>;
};

type SignalCommandConfig<TArgs extends unknown[]> = {
  event: string;
  payload: (...args: TArgs) => object;
};

type ReplyCommandConfig<TArgs extends unknown[]> = SignalCommandConfig<TArgs> & {
  [status: string]: unknown;
};

type CommandConfig<
  TSpec extends SessionSpec,
  TCommand extends keyof TSpec["commands"],
> =
  CommandExpectsReplyOf<TSpec, TCommand> extends true
    ? ReplyCommandConfig<CommandArgsOf<TSpec, TCommand>>
    : SignalCommandConfig<CommandArgsOf<TSpec, TCommand>>;

export type CommandsConfig<TSpec extends SessionSpec> = {
  [K in keyof TSpec["commands"]]: CommandConfig<TSpec, K>;
};

export interface SessionConfig<TSpec extends SessionSpec> {
  topic: string;
  initialSnapshot?: SnapshotOf<TSpec> | null;
  connect?: ConnectConfig<TSpec>;
  events?: Partial<EventsConfig<TSpec>>;
  commands: CommandsConfig<TSpec>;
}

export function createSession<TSpec extends SessionSpec>(
  config: SessionConfig<TSpec>,
): SessionStore<TSpec> {
  let channel!: SessionChannel;
  const runtimeCommands = config.commands as Record<string, RuntimeCommandConfig>;
  const runtimeEvents = config.events as Record<string, RuntimeEventReducer> | undefined;
  const commands = {} as Record<string, unknown>;
  const initialState: SessionState<SnapshotOf<TSpec>> = {
    snapshot: config.initialSnapshot ?? null,
    status: config.initialSnapshot == null ? "loading" : "ready",
    error: null,
  };

  for (const [name, commandConfig] of Object.entries(runtimeCommands)) {
    commands[name] = (...args: unknown[]) => {
      const replyEntries = Object.entries(commandConfig).filter(([key]) => {
        return key !== "event" && key !== "payload";
      });

      // Generic transport resolves reply envelopes and leaves domain interpretation to callers.
      if (replyEntries.length > 0) {
        const push = channel.push(
          commandConfig.event,
          commandConfig.payload(...args) as object,
        );

        return new Promise<CommandReply>((resolve) => {
          for (const [status, handler] of replyEntries) {
            push.receive(status, (response: unknown) => {
              resolve({
                status,
                payload: typeof handler === "function"
                  ? handler(response)
                  : response,
              });
            });
          }
        });
      }

      channel.push(
        commandConfig.event,
        commandConfig.payload(...args) as object,
      );

      return undefined;
    };
  }

  const { subscribe } = readable<SessionState<SnapshotOf<TSpec>>>(
    initialState,
    (_set, update) => {
      channel = socket.channel(config.topic, {}) as SessionChannel;
      const cleanups: Array<() => void> = [];

      const errorRef = channel.onError((reason) => {
        update((current) => {
          const error: SessionError = {
            kind: "transport_error",
            cause: reason,
          };

          if (current.snapshot !== null) {
            // Transport degradation keeps stale data visible if we already have a snapshot.
            return {
              ...current,
              status: "stale",
              error,
            };
          }

          return {
            ...current,
            status: "failed",
            error,
          };
        });
      });

      cleanups.push(() => {
        // Remove local lifecycle handlers before leave to avoid self-inflicted transitions.
        channel.off(CHANNEL_ERROR_EVENT, errorRef);
      });

      const closeRef = channel.onClose(() => {
        update((current) => {
          if (current.snapshot !== null) {
            return {
              ...current,
              status: "stale",
              error: {
                kind: "transport_close",
              },
            };
          }

          return {
            ...current,
            status: "failed",
            error: {
              kind: "transport_close",
            },
          };
        });
      });

      cleanups.push(() => {
        channel.off(CHANNEL_CLOSE_EVENT, closeRef);
      });

      for (const [event, reducer] of Object.entries(runtimeEvents ?? {})) {
        const ref = channel.on(event, (payload: unknown) => {
          update((current) => {
            if (current.snapshot === null) {
              return current;
            }

            return {
              snapshot: reducer(current.snapshot, payload) as SnapshotOf<TSpec>,
              status: "ready",
              error: null,
            };
          });
        });

        cleanups.push(() => {
          channel.off(event, ref);
        });
      }

      // Join establishes the first usable snapshot or an initial failed state.
      channel
        .join()
        .receive("ok", (response: unknown) => {
          update((current) => {
            const snapshot = config.connect?.ok
              ? config.connect.ok(
                current.snapshot,
                response as ConnectOkOf<TSpec>,
              )
              : response as SnapshotOf<TSpec>;

            return {
              snapshot,
              status: "ready",
              error: null,
            };
          });
        })
        .receive("error", (response: unknown) => {
          update((current) => ({
            ...current,
            status: "failed",
            error: {
              kind: "connect_error",
              cause: config.connect?.error
                ? config.connect.error(response as ConnectErrorOf<TSpec>)
                : response,
            },
          }));
        })
        .receive("timeout", () => {
          update((current) => ({
            ...current,
            status: "failed",
            error: {
              kind: "connect_timeout",
              cause: config.connect?.timeout?.() ?? new Error("Connection timed out"),
            },
          }));
        });

      return () => {
        for (const cleanup of cleanups) {
          cleanup();
        }

        channel.leave();
      };
    },
  );

  return {
    subscribe,
    commands: commands as TSpec["commands"],
  };
}
