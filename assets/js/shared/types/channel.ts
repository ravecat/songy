import type { Game } from "~shared/types/game";
import type { Permissions } from "~shared/types/permissions";

export enum PUSH_EVENT {
  START_GAME = "start_game",
  ADVANCE_TURN = "advance_turn",
  MAKE_ASSUMPTION = "make_assumption",
  START_PLAYBACK = "start_playback",
  PAUSE_PLAYBACK = "pause_playback",
  UPDATE_PROVIDER = "update_provider",
  GET_PROVIDER = "get_provider",
  GET_CURRENT_USER = "get_current_user",
}

export enum BROADCAST_EVENT {
  STATE = "state",
  TIMER = "timer",
}

interface PushEventPayloads {
  [PUSH_EVENT.START_GAME]: Record<string, never>;
  [PUSH_EVENT.ADVANCE_TURN]: Record<string, never>;
  [PUSH_EVENT.MAKE_ASSUMPTION]: { position: number };
  [PUSH_EVENT.START_PLAYBACK]: Record<string, never>;
  [PUSH_EVENT.PAUSE_PLAYBACK]: Record<string, never>;
  [PUSH_EVENT.UPDATE_PROVIDER]: { device_id: string };
  [PUSH_EVENT.GET_PROVIDER]: Record<string, never>;
  [PUSH_EVENT.GET_CURRENT_USER]: Record<string, never>;
}

interface OnEventPayloads {
  [BROADCAST_EVENT.STATE]: { game: Game; permissions: Permissions };
  [BROADCAST_EVENT.TIMER]: { remaining: number };
}

declare module "phoenix" {
  interface Channel {
    push<T extends PUSH_EVENT>(event: T, payload: PushEventPayloads[T], timeout?: number): Push;
    on<T extends BROADCAST_EVENT>(event: T, callback: (payload: OnEventPayloads[T]) => void): number;
    off(event: BROADCAST_EVENT, ref?: number): void;
  }
}
