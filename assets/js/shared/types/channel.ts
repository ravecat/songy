export enum PUSH_EVENT {
  START_GAME = "start_game",
  NEXT_PHASE = "next_phase",
  MAKE_ASSUMPTION = "make_assumption",
  REORDER_TIMELINE = "reorder_timeline",
  START_PLAYBACK = "start_playback",
  PAUSE_PLAYBACK = "pause_playback",
  UPDATE_PROVIDER = "update_provider",
  GET_SPOTIFY_TOKEN = "get_spotify_token",
  GET_CURRENT_USER = "get_current_user",
}

interface EventPayloads {
  [PUSH_EVENT.START_GAME]: Record<string, never>;
  [PUSH_EVENT.NEXT_PHASE]: Record<string, never>;
  [PUSH_EVENT.MAKE_ASSUMPTION]: { position: number };
  [PUSH_EVENT.REORDER_TIMELINE]: { track_id: string; position: number };
  [PUSH_EVENT.START_PLAYBACK]: Record<string, never>;
  [PUSH_EVENT.PAUSE_PLAYBACK]: Record<string, never>;
  [PUSH_EVENT.UPDATE_PROVIDER]: { device_id: string };
  [PUSH_EVENT.GET_SPOTIFY_TOKEN]: Record<string, never>;
  [PUSH_EVENT.GET_CURRENT_USER]: Record<string, never>;
}

declare module "phoenix" {
  interface Channel {
    push<T extends PUSH_EVENT>(event: T, payload: EventPayloads[T], timeout?: number): Push;
  }
}
