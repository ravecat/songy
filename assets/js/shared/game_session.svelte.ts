import type {
  Socket,
} from "phoenix";
import type {
  StatePayload,
  UpdateProviderPayload,
} from "~contracts";
import type {
  GameChannelSpec,
  GameConnectionState,
} from "~/contexts/game";
import { useChannel } from "~/shared/hooks/channel.svelte";

type PushEvent = keyof GameChannelSpec["push"] & string;

type EventPayload<TEvent extends PushEvent> =
  GameChannelSpec["push"][TEvent] extends { payload: infer TPayload extends object }
  ? TPayload
  : Record<string, never>;

type OkReply<TEvent extends PushEvent> =
  GameChannelSpec["push"][TEvent] extends {
    reply: infer TReply extends Partial<Record<string, unknown>>;
  }
  ? TReply extends { ok: infer TOk }
  ? TOk
  : never
  : never;

function timeoutError(event: string) {
  return new Error(`${event} timed out`);
}

export function createGameSession(
  options: {
    socket: Socket;
    topic: string;
  },
) {
  let state = $state<StatePayload | null>(null);
  let timer = $state<number | null>(null);
  let error = $state<unknown>(null);
  let connection = $state<GameConnectionState>("connecting");

  function setReady(payload: StatePayload) {
    state = payload;
    error = null;
    connection = "ready";

    if (payload.game.turn?.phase !== "challenging") {
      timer = null;
    }
  }

  function setFailure(nextError: unknown, nextConnection: GameConnectionState) {
    error = nextError;
    connection = nextConnection;
  }

  function handleTransportFailure(nextError: unknown) {
    if (connection === "closed") {
      return;
    }

    if (state) {
      setFailure(nextError, "reconnecting");
      return;
    }

    setFailure(nextError, "error");
  }

  const channel = useChannel<GameChannelSpec>({
    socket: options.socket,
    topic: options.topic,
    on: {
      state: (payload) => {
        setReady(payload);
      },
      timer: ({ remaining }) => {
        timer = remaining;
      },
    },
    join: {
      ok: (payload) => {
        setReady(payload);
      },
      error: (payload) => {
        setFailure(payload, "error");
      },
      timeout: () => {
        setFailure(new Error("Connection timed out"), "error");
      },
    },
    onError: () => {
      handleTransportFailure(new Error(`Channel error on ${options.topic}`));
    },
    onClose: () => {
      handleTransportFailure(
        new Error("Connection closed unexpectedly"),
      );
    },
  });

  $effect(() => {
    return () => {
      connection = "closed";
    };
  });

  function pushWithoutReply<TEvent extends PushEvent>(
    event: TEvent,
    payload: EventPayload<TEvent>,
  ) {
    channel.push(event, payload);
    return Promise.resolve();
  }

  function pushWithReply<TEvent extends PushEvent>(
    event: TEvent,
    payload: EventPayload<TEvent>,
  ): Promise<OkReply<TEvent>> {
    return new Promise((resolve, reject) => {
      const push = channel.push(event, payload) as {
        receive(status: string, callback: (reply?: unknown) => void): typeof push;
      };

      push
        .receive("ok", (reply) => resolve(reply as OkReply<TEvent>))
        .receive("error", reject)
        .receive("timeout", () => reject(timeoutError(event)));
    });
  }

  return {
    get state() {
      return state;
    },
    get game() {
      return state?.game ?? null;
    },
    get permissions() {
      return state?.permissions ?? null;
    },
    get timer() {
      return timer;
    },
    get connection() {
      return connection;
    },
    get error() {
      return error;
    },

    startGame() {
      return pushWithoutReply("start_game", {});
    },
    advanceTurn() {
      return pushWithReply("advance_turn", {});
    },
    makeAssumption(position: number) {
      return pushWithReply("make_assumption", { position });
    },
    startPlayback() {
      return pushWithReply("start_playback", {});
    },
    pausePlayback() {
      return pushWithReply("pause_playback", {});
    },
    updateProvider(payload: UpdateProviderPayload) {
      return pushWithReply("update_provider", payload);
    },
    getProvider() {
      return pushWithReply("get_provider", {});
    },
    getCurrentUser() {
      return pushWithReply("get_current_user", {});
    },
  };
}
