import { createContext } from "svelte";
import type {
  AssumptionPayload,
  Game,
  JoinReply,
  Permissions,
  StatePayload,
  TimerPayload,
  UpdateProviderPayload,
  User,
} from "~contracts";
import type { Channel } from "~/shared/hooks/channel.svelte";

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
    get_current_user: {
      reply: { ok: User };
    };
  };
}

interface GameContext {
  game: Game;
  permissions: Permissions;
  channel: Channel<GameChannelSpec>;
}

export const [getGameContext, setGameContext] = createContext<GameContext>();
