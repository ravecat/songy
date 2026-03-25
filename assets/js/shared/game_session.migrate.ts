import type {
  StatePayload,
} from "~contracts";

export type SessionConnectionState =
  | "connecting"
  | "ready"
  | "reconnecting"
  | "closed"
  | "error";

export interface SessionCore<TSnapshot> {
  readonly snapshot: TSnapshot | null;
  readonly connection: SessionConnectionState;
  readonly error: unknown;

  applySnapshot(payload: TSnapshot): void;
  applyFailure(nextError: unknown): void;
  close(): void;
}

export interface SongySessionState extends SessionCore<StatePayload> {
  readonly game: StatePayload["game"] | null;
  readonly permissions: StatePayload["permissions"] | null;
  readonly timer: number | null;

  applyTimer(remaining: number): void;
}

export function createSessionCore<TSnapshot>(): SessionCore<TSnapshot> {
  let snapshot: TSnapshot | null = null;
  let error: unknown = null;
  let connection: SessionConnectionState = "connecting";

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

    applySnapshot(payload) {
      snapshot = payload;
      error = null;
      connection = "ready";
    },

    applyFailure(nextError) {
      if (connection === "closed") {
        return;
      }

      error = nextError;
      connection = snapshot ? "reconnecting" : "error";
    },

    close() {
      connection = "closed";
    },
  };
}

export function createSongySessionState(): SongySessionState {
  const core = createSessionCore<StatePayload>();
  let timer: number | null = null;

  return {
    get snapshot() {
      return core.snapshot;
    },
    get game() {
      return core.snapshot?.game ?? null;
    },
    get permissions() {
      return core.snapshot?.permissions ?? null;
    },
    get timer() {
      return timer;
    },
    get connection() {
      return core.connection;
    },
    get error() {
      return core.error;
    },

    applySnapshot(payload) {
      core.applySnapshot(payload);

      if (payload.game.turn?.phase !== "challenging") {
        timer = null;
      }
    },

    applyTimer(remaining) {
      timer = remaining;
    },

    applyFailure(nextError) {
      core.applyFailure(nextError);
    },

    close() {
      core.close();
    },
  };
}

export const createGameSessionState = createSongySessionState;
