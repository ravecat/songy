import type {
  AssumptionPayload,
  JoinReply,
  StatePayload,
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

export interface GameSnapshot {
  readonly game: StatePayload["game"];
  readonly permissions: StatePayload["permissions"];
}

export interface GameSession {
  readonly snapshot: GameSnapshot | null;
  readonly connection: GameConnectionState;
  readonly error: unknown;

  startGame(): Promise<void>;
  advanceTurn(): Promise<void>;
  makeAssumption(position: number): Promise<void>;
  startPlayback(): Promise<void>;
  pausePlayback(): Promise<void>;
  dispose(): void;
}

export interface GameChannelSpec {
  on: {
    state: StatePayload;
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

  let snapshot = $state<GameSnapshot | null>(null);
  let error = $state<unknown>(null);
  let connection = $state<GameConnectionState>("connecting");
  const teardowns: Array<() => void> = [];
  let disposed = false;

  function setFailure(nextError: unknown, nextConnection: GameConnectionState) {
    error = nextError;
    connection = nextConnection;
  }

  function applySnapshot(payload: StatePayload) {
    snapshot = {
      game: payload.game,
      permissions: payload.permissions,
    };
    error = null;
    connection = "ready";
  }

  function applyFailure(nextError: unknown, recoverable: boolean) {
    if (connection === "closed") {
      return;
    }

    if (recoverable && snapshot !== null) {
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
    get snapshot() {
      return snapshot;
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
