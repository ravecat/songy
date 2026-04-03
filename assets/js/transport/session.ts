import type { Channel, Push } from "phoenix";
import type { Readable } from "svelte/store";
import { readable } from "svelte/store";
import socket from "~/transport/socket";

type ReplyPush = Omit<Push, "receive"> & {
  receive(status: string, callback: (payload?: unknown) => void): ReplyPush;
};

type RuntimeEventReducer = (snapshot: unknown, payload: unknown) => unknown;

type RuntimeCommandConfig = {
  event: string;
  [status: string]: unknown;
};

const CHANNEL_CLOSE_EVENT = "phx_close";
const CHANNEL_ERROR_EVENT = "phx_error";

type SessionStatus =
  | "loading"
  | "ready"
  | "stale"
  | "failed";

interface CommandReply<TStatus extends string = string, TPayload = unknown> {
  status: TStatus;
  payload: TPayload;
}

type SessionCommandContract = {
  event: string;
  payload?: Record<string, unknown>;
  reply?: Record<string, unknown>;
};

type SessionContract = {
  snapshot?: unknown;
  connect?: {
    ok?: unknown;
    error?: unknown;
  };
  events?: Record<string, unknown>;
  commands?: Record<string, SessionCommandContract>;
};

type UnknownSessionKeys<TSpec extends SessionContract> =
  Exclude<keyof TSpec, keyof SessionContract>;

type UnknownConnectKeys<TSpec extends SessionContract> =
  TSpec extends { connect: infer TConnect }
    ? Exclude<
      keyof NonNullable<TConnect>,
      keyof NonNullable<SessionContract["connect"]>
    >
    : never;

type UnknownCommandKeys<TSpec extends SessionContract> =
  TSpec extends {
    commands: infer TCommands extends Record<string, SessionCommandContract>;
  }
    ? {
      [TCommand in keyof TCommands]:
        Exclude<keyof TCommands[TCommand], keyof SessionCommandContract>;
    }[keyof TCommands]
    : never;

type SessionSpecValidation<TSpec extends SessionContract> =
  ([UnknownSessionKeys<TSpec>] extends [never]
    ? {}
    : {
      __session_spec_error__: `Unknown session spec keys: ${UnknownSessionKeys<TSpec> & string}`;
    }) &
  ([UnknownConnectKeys<TSpec>] extends [never]
    ? {}
    : {
      __session_connect_spec_error__: `Unknown connect spec keys: ${UnknownConnectKeys<TSpec> & string}`;
    }) &
  ([UnknownCommandKeys<TSpec>] extends [never]
    ? {}
    : {
      __session_command_spec_error__: `Unknown command spec keys: ${UnknownCommandKeys<TSpec> & string}`;
    });

type SessionError =
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

type SnapshotOf<TSpec extends SessionContract> =
  TSpec extends { snapshot: infer TSnapshot }
    ? TSnapshot
    : unknown;

type ConnectOkOf<TSpec extends SessionContract> =
  TSpec extends { connect: { ok?: infer TOk } }
    ? TOk
    : SnapshotOf<TSpec>;

type ConnectErrorOf<TSpec extends SessionContract> =
  TSpec extends { connect: { error?: infer TError } }
    ? TError
    : unknown;

type EventMapOf<TSpec extends SessionContract> =
  TSpec extends { events: infer TEvents extends Record<string, unknown> }
    ? TEvents
    : Record<never, never>;

type CommandMapOf<TSpec extends SessionContract> =
  TSpec extends {
    commands: infer TCommands extends Record<string, SessionCommandContract>;
  }
    ? TCommands
    : Record<never, never>;

type CommandNameOf<TSpec extends SessionContract> =
  Extract<keyof CommandMapOf<TSpec>, string>;

type CommandSpecOf<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> = CommandMapOf<TSpec>[TCommand];

type EventPayloadOf<
  TSpec extends SessionContract,
  TEvent extends keyof EventMapOf<TSpec>,
> = EventMapOf<TSpec>[TEvent];

type CommandEventOf<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> =
  CommandSpecOf<TSpec, TCommand> extends { event: infer TEvent extends string }
    ? TEvent
    : never;

type CommandArgumentOf<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> =
  CommandSpecOf<TSpec, TCommand> extends { payload: infer TPayload }
    ? TPayload
    : never;

type CommandReplyMapOf<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> =
  CommandSpecOf<TSpec, TCommand> extends {
    reply: infer TReply extends Record<string, unknown>;
  }
    ? TReply
    : Record<never, never>;

type CommandStatusOf<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> = Extract<keyof CommandReplyMapOf<TSpec, TCommand>, string>;

type CommandReplyPayloadOf<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
  TStatus extends CommandStatusOf<TSpec, TCommand>,
> = CommandReplyMapOf<TSpec, TCommand>[TStatus];

type CommandExpectsReplyOf<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> =
  [CommandStatusOf<TSpec, TCommand>] extends [never] ? false : true;

type CommandReplyResultOf<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> = {
  [TStatus in CommandStatusOf<TSpec, TCommand>]:
    CommandReply<TStatus, CommandReplyPayloadOf<TSpec, TCommand, TStatus>>;
}[CommandStatusOf<TSpec, TCommand>];

type SignalCommandFn<TPayload> =
  [TPayload] extends [never]
    ? () => void
    : (payload: TPayload) => void;

type ReplyCommandFn<TPayload, TResult> =
  [TPayload] extends [never]
    ? () => Promise<TResult>
    : (payload: TPayload) => Promise<TResult>;

type CommandFnOf<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> =
  CommandExpectsReplyOf<TSpec, TCommand> extends true
    ? ReplyCommandFn<
      CommandArgumentOf<TSpec, TCommand>,
      CommandReplyResultOf<TSpec, TCommand>
    >
    : SignalCommandFn<CommandArgumentOf<TSpec, TCommand>>;

type CommandFnsOf<TSpec extends SessionContract> = {
  [TCommand in CommandNameOf<TSpec>]: CommandFnOf<TSpec, TCommand>;
};

interface SessionState<TSnapshot> {
  readonly snapshot: TSnapshot | null;
  readonly status: SessionStatus;
  readonly error: SessionError | null;
}

type SessionStore<TSpec extends SessionContract> =
  Readable<SessionState<SnapshotOf<TSpec>>> & {
    commands: CommandFnsOf<TSpec>;
  };

type RuntimeConnectConfig<TSpec extends SessionContract> = {
  ok?: (
    snapshot: Readonly<SnapshotOf<TSpec>> | null,
    reply: ConnectOkOf<TSpec>,
  ) => SnapshotOf<TSpec>;
  error?: (reply: ConnectErrorOf<TSpec>) => unknown;
  timeout?: () => unknown;
};

type ConnectConfig<TSpec extends SessionContract> =
  RuntimeConnectConfig<TSpec>;

type EventsConfig<TSpec extends SessionContract> =
  {
    [K in keyof EventMapOf<TSpec>]?: (
      snapshot: Readonly<SnapshotOf<TSpec>>,
      payload: EventPayloadOf<TSpec, K>,
    ) => SnapshotOf<TSpec>;
  };

type SignalCommandConfig<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> = {
  event: CommandEventOf<TSpec, TCommand>;
};

type ReplyCommandCallbacks<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> = {
  [TStatus in CommandStatusOf<TSpec, TCommand>]: (
    reply: unknown,
  ) => CommandReplyPayloadOf<TSpec, TCommand, TStatus>;
};

type ReplyCommandConfig<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> = SignalCommandConfig<TSpec, TCommand> &
  ReplyCommandCallbacks<TSpec, TCommand>;

type CommandConfig<
  TSpec extends SessionContract,
  TCommand extends CommandNameOf<TSpec>,
> =
  CommandExpectsReplyOf<TSpec, TCommand> extends true
    ? ReplyCommandConfig<TSpec, TCommand>
    : SignalCommandConfig<TSpec, TCommand>;

type CommandsConfig<TSpec extends SessionContract> =
  {
    [K in CommandNameOf<TSpec>]: CommandConfig<TSpec, K>;
  };

type SessionConfig<TSpec extends SessionContract> =
  {
    topic: string;
    snapshot?: SnapshotOf<TSpec> | null;
    connect?: ConnectConfig<TSpec>;
    events?: Partial<EventsConfig<TSpec>>;
    commands: CommandsConfig<TSpec>;
  };

export function createSession<TSpec extends SessionContract>(
  config: SessionConfig<TSpec> & SessionSpecValidation<TSpec>,
): SessionStore<TSpec> {
  let channel!: Channel;
  const runtimeCommands = config.commands as unknown as Record<string, RuntimeCommandConfig>;
  const runtimeConnect = config.connect as RuntimeConnectConfig<TSpec> | undefined;
  const runtimeEvents = config.events as Record<string, RuntimeEventReducer> | undefined;
  const commands = {} as Record<string, unknown>;
  const initialState: SessionState<SnapshotOf<TSpec>> = {
    snapshot: config.snapshot ?? null,
    status: config.snapshot == null ? "loading" : "ready",
    error: null,
  };

  for (const [name, commandDefinition] of Object.entries(runtimeCommands)) {
    commands[name] = (payloadArg?: unknown) => {
      const replyEntries = Object.entries(commandDefinition).filter(([key]) => {
        return key !== "event";
      });
      const payload = (payloadArg ?? {}) as object;

      // Generic transport resolves reply envelopes and leaves domain interpretation to callers.
      if (replyEntries.length > 0) {
        const push = channel.push(
          commandDefinition.event,
          payload,
        ) as ReplyPush;

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
        commandDefinition.event,
        payload,
      );

      return undefined;
    };
  }

  const { subscribe } = readable<SessionState<SnapshotOf<TSpec>>>(
    initialState,
    (_set, update) => {
      channel = socket.channel(config.topic, {}) as Channel;
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
            const snapshot = runtimeConnect?.ok
              ? runtimeConnect.ok(
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
              cause: runtimeConnect?.error
                ? runtimeConnect.error(response as ConnectErrorOf<TSpec>)
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
              cause: runtimeConnect?.timeout?.() ?? new Error("Connection timed out"),
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
    commands: commands as CommandFnsOf<TSpec>,
  };
}
