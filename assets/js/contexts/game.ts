import { createContext } from "svelte";
import type {
  AssumptionPayload,
  Game,
  JoinReply,
  Permissions,
  StatePayload,
  TimerPayload,
  UpdateProviderPayload,
} from "~contracts";

export type GameConnectionState =
  | "connecting"
  | "ready"
  | "reconnecting"
  | "closed"
  | "error";

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
    advance_turn: {};
    make_assumption: { payload: AssumptionPayload };
    start_playback: {};
    pause_playback: {};
    update_provider: { payload: UpdateProviderPayload };
    get_provider: {
      reply: { ok: { token: string } };
    };
  };
}

export interface GameSession {
  readonly state: StatePayload | null;
  readonly game: Game | null;
  readonly permissions: Permissions | null;
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
}

export type GameContext = GameSession;

export const [getGameContext, setGameContext] = createContext<GameSession>();
