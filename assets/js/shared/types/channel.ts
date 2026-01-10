import type { Game } from "./game";
import type { Permissions } from "./permissions";

/**
 * Client-to-server push events
 */
export enum PUSH_EVENT {
  START_GAME = "start_game",
  NEXT_PHASE = "next_phase",
  MAKE_ASSUMPTION = "make_assumption",
  REORDER_TIMELINE = "reorder_timeline",
  START_PLAYBACK = "start_playback",
  PAUSE_PLAYBACK = "pause_playback",
  UPDATE_PROVIDER = "update_provider",
  GET_PROVIDER = "get_provider",
  GET_CURRENT_USER = "get_current_user",
}

/**
 * Server-to-client broadcast events
 */
export enum BROADCAST_EVENT {
  STATE = "state",
}

/**
 * State event payload containing game state and user permissions
 */
export interface StateEventPayload {
  game: Game;
  permissions: Permissions;
}

interface PushEventPayloads {
  [PUSH_EVENT.START_GAME]: Record<string, never>;
  [PUSH_EVENT.NEXT_PHASE]: Record<string, never>;
  [PUSH_EVENT.MAKE_ASSUMPTION]: { position: number };
  [PUSH_EVENT.REORDER_TIMELINE]: { track_id: string; position: number };
  [PUSH_EVENT.START_PLAYBACK]: Record<string, never>;
  [PUSH_EVENT.PAUSE_PLAYBACK]: Record<string, never>;
  [PUSH_EVENT.UPDATE_PROVIDER]: { device_id: string };
  [PUSH_EVENT.GET_PROVIDER]: Record<string, never>;
  [PUSH_EVENT.GET_CURRENT_USER]: Record<string, never>;
}

declare module "phoenix" {
  interface Channel {
    push<T extends PUSH_EVENT>(event: T, payload: PushEventPayloads[T], timeout?: number): Push;
  }
}
