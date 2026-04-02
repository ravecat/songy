import type {
  AssumptionPayload,
  JoinReply,
  StatePayload,
} from "~contracts";
import {
  type CommandReply,
  createSession,
  type SessionSpec,
  type SessionState,
  type SessionStore,
} from "~/transport/session";

export type GameSnapshot = StatePayload;
export type GameSessionStatus = SessionState<GameSnapshot>["status"];
export type GameSessionState = SessionState<GameSnapshot>;
export type GameCommandResult =
  | CommandReply<"ok", void>
  | CommandReply<"error", unknown>
  | CommandReply<"timeout", Error>;

export interface GameSessionSpec extends SessionSpec {
  connect: {
    ok: Extract<JoinReply, { status: "ok" }>["response"];
    error: Extract<JoinReply, { status: "error" }>["response"];
  };
  events: {
    state: StatePayload;
  };
  snapshot: StatePayload;
  commands: {
    startGame(): void;
    advanceTurn(): Promise<GameCommandResult>;
    makeAssumption(position: number): Promise<GameCommandResult>;
    startPlayback(): Promise<GameCommandResult>;
    pausePlayback(): Promise<GameCommandResult>;
  };
}
export type GameSessionStore = SessionStore<GameSessionSpec>;

function timeoutError(event: string) {
  return new Error(`${event} timed out`);
}

export function createGameSession(topic: string): GameSessionStore {
  return createSession<GameSessionSpec>({
    topic,
    connect: {
      error: (reply) => reply,
      timeout: () => new Error("Connection timed out"),
    },
    events: {
      state: (_snapshot, payload) => payload,
    },
    commands: {
      startGame: {
        event: "start_game",
        payload: () => ({}),
      },
      advanceTurn: {
        event: "advance_turn",
        payload: () => ({}),
        ok: () => undefined,
        error: (reply: unknown) => reply,
        timeout: () => timeoutError("advance_turn"),
      },
      makeAssumption: {
        event: "make_assumption",
        payload: (position: number): AssumptionPayload => ({ position }),
        ok: () => undefined,
        error: (reply: unknown) => reply,
        timeout: () => timeoutError("make_assumption"),
      },
      startPlayback: {
        event: "start_playback",
        payload: () => ({}),
        ok: () => undefined,
        error: (reply: unknown) => reply,
        timeout: () => timeoutError("start_playback"),
      },
      pausePlayback: {
        event: "pause_playback",
        payload: () => ({}),
        ok: () => undefined,
        error: (reply: unknown) => reply,
        timeout: () => timeoutError("pause_playback"),
      },
    },
  });
}
