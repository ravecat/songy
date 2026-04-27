import type { Channel } from "phoenix";
import type { Readable } from "svelte/store";
import { readable } from "svelte/store";
import socket from "~/transport/socket";

const CHANNEL_CLOSE_EVENT = "phx_close";
const CHANNEL_ERROR_EVENT = "phx_error";

type RuntimeEventReducer<TSnapshot> =
  (snapshot: TSnapshot | null, payload: unknown) => TSnapshot;

type SessionStatus =
  | "loading"
  | "ready"
  | "stale"
  | "failed";

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

type SessionSpec = {
  snapshot?: unknown;
  connect?: {
    ok?: unknown;
    error?: unknown;
  };
  events?: Record<string, unknown>;
};

type SnapshotOf<TSpec extends SessionSpec> =
  TSpec extends { snapshot: infer TSnapshot }
  ? TSnapshot
  : unknown;

type ConnectOkOf<TSpec extends SessionSpec> =
  TSpec extends { connect: { ok?: infer TOk } }
  ? TOk
  : SnapshotOf<TSpec>;

type ConnectErrorOf<TSpec extends SessionSpec> =
  TSpec extends { connect: { error?: infer TError } }
  ? TError
  : unknown;

type EventMapOf<TSpec extends SessionSpec> =
  TSpec extends { events: infer TEvents extends Record<string, unknown> }
  ? TEvents
  : Record<never, never>;

interface SessionState<TSnapshot> {
  readonly snapshot: TSnapshot | null;
  readonly status: SessionStatus;
  readonly error: SessionError | null;
}

type SessionConnectConfig<TSpec extends SessionSpec> = {
  ok?: (
    snapshot: Readonly<SnapshotOf<TSpec>> | null,
    reply: ConnectOkOf<TSpec>,
  ) => SnapshotOf<TSpec>;
  error?: (reply: ConnectErrorOf<TSpec>) => unknown;
  timeout?: () => unknown;
};

type SessionEventsConfig<TSpec extends SessionSpec> =
  {
    [K in keyof EventMapOf<TSpec>]?: (
      snapshot: Readonly<SnapshotOf<TSpec>> | null,
      payload: EventMapOf<TSpec>[K],
    ) => SnapshotOf<TSpec>;
  };

type SessionConfig<TSpec extends SessionSpec> = {
  topic: string;
  snapshot?: SnapshotOf<TSpec> | null;
  connect?: SessionConnectConfig<TSpec>;
  events?: Partial<SessionEventsConfig<TSpec>>;
};

type SessionCore<TSpec extends SessionSpec> =
  Readable<SessionState<SnapshotOf<TSpec>>> & {
    push: Channel["push"];
  };

type Session<TSpec extends SessionSpec> =
  SessionCore<TSpec> & {
    extend<TExtension extends object>(
      build: (session: SessionCore<TSpec>) => TExtension,
    ): Readable<SessionState<SnapshotOf<TSpec>>> & TExtension;
  };

export function createSession<TSpec extends SessionSpec>(
  config: SessionConfig<TSpec>,
): Session<TSpec> {
  let channel: Channel | null = null;

  const initialState: SessionState<SnapshotOf<TSpec>> = {
    snapshot: config.snapshot ?? null,
    status: config.snapshot == null ? "loading" : "ready",
    error: null,
  };

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
        channel?.off(CHANNEL_ERROR_EVENT, errorRef);
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
        channel?.off(CHANNEL_CLOSE_EVENT, closeRef);
      });

      for (const [event, reducer] of Object.entries(config.events ?? {})) {
        const handleEvent = reducer as RuntimeEventReducer<SnapshotOf<TSpec>>;
        const ref = channel.on(event, (payload) => {
          update((current) => {
            return {
              snapshot: handleEvent(current.snapshot, payload),
              status: "ready",
              error: null,
            };
          });
        });

        cleanups.push(() => {
          channel?.off(event, ref);
        });
      }

      channel
        .join()
        .receive("ok", (response: ConnectOkOf<TSpec>) => {
          update((current) => ({
            snapshot: config.connect?.ok
              ? config.connect.ok(current.snapshot, response)
              : response as SnapshotOf<TSpec>,
            status: "ready",
            error: null,
          }));
        })
        .receive("error", (response: ConnectErrorOf<TSpec>) => {
          update((current) => ({
            ...current,
            status: "failed",
            error: {
              kind: "connect_error",
              cause: config.connect?.error
                ? config.connect.error(response)
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
              cause: config.connect?.timeout?.(),
            },
          }));
        });

      return () => {
        for (const cleanup of cleanups) {
          cleanup();
        }

        channel?.leave();
        channel = null;
      };
    },
  );

  const push: Channel["push"] = (event, payload, timeout) => {
    if (!channel) {
      throw new Error(`Cannot push "${event}" before joining "${config.topic}"`);
    }

    return channel.push(event, payload, timeout);
  };
  const sessionCore: SessionCore<TSpec> = {
    subscribe,
    push,
  };

  return {
    ...sessionCore,
    extend(build) {
      return {
        ...build(sessionCore),
        subscribe,
      };
    },
  };
}
