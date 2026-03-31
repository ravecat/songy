import type {
  AssumptionPayload,
  JoinReply,
  StatePayload,
} from "~contracts";
import type { Readable } from "svelte/store";
import { writable } from "svelte/store";
import {
  type Transport,
} from "~/transport/channel";

export type GameSessionStatus =
  | "loading"
  | "ready"
  | "stale"
  | "failed"
  | "disposed";

export type GameSnapshot = StatePayload;

export interface GameSessionState {
  readonly snapshot: GameSnapshot | null;
  readonly status: GameSessionStatus;
  readonly error: unknown;
}

export interface GameSessionStore extends Readable<GameSessionState> {
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
type GameReplyCommand = Exclude<GameCommand, "start_game">;

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

function timeoutError(event: string) {
  return new Error(`${event} timed out`);
}

export function createGameSession(
  transport: Transport<GameChannelSpec>,
): GameSessionStore {
  const initialState: GameSessionState = {
    snapshot: null,
    status: "loading",
    error: null,
  };
  const store = writable<GameSessionState>(initialState);
  const { subscribe, set } = store;
  const teardowns: Array<() => void> = [];
  let disposed = false;
  let state = initialState;

  function setState(nextState: GameSessionState) {
    state = nextState;
    set(nextState);
  }

  function onSnapshot(payload: StatePayload) {
    setState({
      snapshot: payload,
      status: "ready",
      error: null,
    });
  }

  function applyFailure(nextError: unknown, recoverable: boolean) {
    if (state.status === "disposed") {
      return;
    }

    if (recoverable && state.snapshot !== null) {
      setState({
        ...state,
        status: "stale",
        error: nextError,
      });
      return;
    }

    setState({
      ...state,
      status: "failed",
      error: nextError,
    });
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
    transport.subscribe("state", onSnapshot),
  );

  void transport.join().then((result) => {
    if (disposed) {
      return;
    }

    switch (result.status) {
      case "ok":
        onSnapshot(result.response);
        return;

      case "error":
        applyFailure(result.response, false);
        return;

      case "timeout":
        applyFailure(new Error("Connection timed out"), false);
        return;
    }
  });

  function pushAndExpectOk<TEvent extends GameReplyCommand>(
    event: TEvent,
    payload: GameCommandPayload<TEvent>,
  ): Promise<GameCommandResult<TEvent>> {
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
    subscribe,

    startGame() {
      void transport.push("start_game", {});
      return Promise.resolve();
    },
    advanceTurn() {
      return pushAndExpectOk("advance_turn", {});
    },
    makeAssumption(position: number) {
      return pushAndExpectOk("make_assumption", { position });
    },
    startPlayback() {
      return pushAndExpectOk("start_playback", {});
    },
    pausePlayback() {
      return pushAndExpectOk("pause_playback", {});
    },
    dispose() {
      if (disposed) {
        return;
      }

      disposed = true;

      for (const teardown of teardowns) {
        teardown();
      }

      setState({
        ...state,
        status: "disposed",
      });
      transport.dispose();
    },
  };
}
