import type {
  AssumptionPayload,
  JoinReply,
  StatePayload,
  TimerPayload,
  UpdateProviderPayload,
} from "~contracts";
import {
  createTransport,
  type Transport,
} from "~/shared/transport";
import socket from "~/socket";

export type GameConnectionState =
  | "connecting"
  | "ready"
  | "reconnecting"
  | "closed"
  | "error";

export interface GameSession {
  readonly state: StatePayload | null;
  readonly game: StatePayload["game"] | null;
  readonly permissions: StatePayload["permissions"] | null;
  readonly timer: number | null;
  readonly connection: GameConnectionState;
  readonly error: unknown;

  startGame(): Promise<void>;
  advanceTurn(): Promise<void>;
  makeAssumption(position: number): Promise<void>;
  startPlayback(): Promise<void>;
  pausePlayback(): Promise<void>;
  updateProvider(payload: UpdateProviderPayload): Promise<void>;
  getProvider(): Promise<{ token: string }>;
  dispose(): void;
}

export interface GameChannelSpec {
  on: {
    state: StatePayload;
    timer: TimerPayload;
  };
  join: {
    ok: Extract<JoinReply, { status: "ok" }>["response"];
    error: Extract<JoinReply, { status: "error" }>["response"];
  };
  push: {
    start_game: {};
    advance_turn: {
      reply: { ok: void };
    };
    make_assumption: {
      payload: AssumptionPayload;
      reply: { ok: void };
    };
    start_playback: {
      reply: { ok: void };
    };
    pause_playback: {
      reply: { ok: void };
    };
    update_provider: {
      payload: UpdateProviderPayload;
      reply: { ok: void };
    };
    get_provider: {
      reply: { ok: { token: string } };
    };
  };
}

export type GameCommand = keyof GameChannelSpec["push"] & string;

export type GameCommandPayload<TEvent extends GameCommand> =
  GameChannelSpec["push"][TEvent] extends { payload: infer TPayload extends object }
  ? TPayload
  : Record<string, never>;

export type GameCommandResult<TEvent extends GameCommand> =
  GameChannelSpec["push"][TEvent] extends {
    reply: { ok: infer TOk };
  }
  ? TOk
  : void;

interface GameSessionTransportOptions {
  transport: Transport<GameChannelSpec>;
}

interface GameSessionTopicOptions {
  topic: string;
  payload?: object;
}

type GameSessionOptions =
  | GameSessionTransportOptions
  | GameSessionTopicOptions;

const commandsWithReplies = new Set<GameCommand>([
  "advance_turn",
  "make_assumption",
  "start_playback",
  "pause_playback",
  "update_provider",
  "get_provider",
]);

function timeoutError(event: string) {
  return new Error(`${event} timed out`);
}

export function createGameSession(
  options: GameSessionOptions,
): GameSession {
  const transport = "transport" in options
    ? options.transport
    : createTransport<GameChannelSpec>({
      socket,
      topic: options.topic,
      payload: options.payload,
    });

  let state = $state<StatePayload | null>(null);
  let timer = $state<number | null>(null);
  let error = $state<unknown>(null);
  let connection = $state<GameConnectionState>("connecting");
  const teardowns: Array<() => void> = [];
  let disposed = false;

  function setFailure(nextError: unknown, nextConnection: GameConnectionState) {
    error = nextError;
    connection = nextConnection;
  }

  function applySnapshot(payload: StatePayload) {
    state = payload;
    error = null;
    connection = "ready";

    if (payload.game.turn?.phase !== "challenging") {
      timer = null;
    }
  }

  function applyTimerSync(remaining: number) {
    timer = remaining;
  }

  function applyFailure(nextError: unknown, recoverable: boolean) {
    if (connection === "closed") {
      return;
    }

    if (recoverable && state) {
      setFailure(nextError, "reconnecting");
      return;
    }

    setFailure(nextError, "error");
  }

  teardowns.push(
    transport.onFailure((failure) => {
      if (disposed) {
        return;
      }

      switch (failure.kind) {
        case "error":
          applyFailure(failure.error, true);
          return;

        case "close":
          applyFailure(new Error("Connection closed unexpectedly"), true);
          return;
      }
    }),
  );

  teardowns.push(
    transport.subscribe("state", applySnapshot),
  );

  teardowns.push(
    transport.subscribe("timer", ({ remaining }) => {
      applyTimerSync(remaining);
    }),
  );

  void transport.join().then((result) => {
    if (disposed) {
      return;
    }

    switch (result.status) {
      case "ok":
        applySnapshot(result.response);
        return;

      case "error":
        applyFailure(result.response, false);
        return;

      case "timeout":
        applyFailure(new Error("Connection timed out"), false);
        return;
    }
  });

  function command<TEvent extends GameCommand>(
    event: TEvent,
    payload: GameCommandPayload<TEvent>,
  ): Promise<GameCommandResult<TEvent>> {
    if (!commandsWithReplies.has(event)) {
      void transport.push(event, payload);
      return Promise.resolve(undefined as GameCommandResult<TEvent>);
    }

    return transport.push(event, payload).then((result) => {
      switch (result.status) {
        case "ok":
          return result.response as GameCommandResult<TEvent>;

        case "error":
          throw result.response;

        case "timeout":
          throw timeoutError(event);
      }
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
      return command("start_game", {});
    },
    advanceTurn() {
      return command("advance_turn", {});
    },
    makeAssumption(position: number) {
      return command("make_assumption", { position });
    },
    startPlayback() {
      return command("start_playback", {});
    },
    pausePlayback() {
      return command("pause_playback", {});
    },
    updateProvider(payload: UpdateProviderPayload) {
      return command("update_provider", payload);
    },
    getProvider() {
      return command("get_provider", {});
    },
    dispose() {
      if (disposed) {
        return;
      }

      disposed = true;

      for (const teardown of teardowns) {
        teardown();
      }

      connection = "closed";
      transport.dispose();
    },
  };
}
