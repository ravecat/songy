import type {
  AssumptionPayload,
  StatePayload,
  TimerPayload,
  UpdateProviderPayload,
} from "~contracts";

export const PUSH_EVENT = {
  START_GAME: "start_game",
  ADVANCE_TURN: "advance_turn",
  MAKE_ASSUMPTION: "make_assumption",
  START_PLAYBACK: "start_playback",
  PAUSE_PLAYBACK: "pause_playback",
  UPDATE_PROVIDER: "update_provider",
  GET_PROVIDER: "get_provider",
  GET_CURRENT_USER: "get_current_user",
} as const;

export const BROADCAST_EVENT = {
  STATE: "state",
  TIMER: "timer",
} as const;

export type PushEvent = (typeof PUSH_EVENT)[keyof typeof PUSH_EVENT];
export type BroadcastEvent =
  (typeof BROADCAST_EVENT)[keyof typeof BROADCAST_EVENT];

type StrictEmptyPayload = Record<string, never>;

interface PushEventPayloads {
  [PUSH_EVENT.START_GAME]: StrictEmptyPayload;
  [PUSH_EVENT.ADVANCE_TURN]: StrictEmptyPayload;
  [PUSH_EVENT.MAKE_ASSUMPTION]: AssumptionPayload;
  [PUSH_EVENT.START_PLAYBACK]: StrictEmptyPayload;
  [PUSH_EVENT.PAUSE_PLAYBACK]: StrictEmptyPayload;
  [PUSH_EVENT.UPDATE_PROVIDER]: UpdateProviderPayload;
  [PUSH_EVENT.GET_PROVIDER]: StrictEmptyPayload;
  [PUSH_EVENT.GET_CURRENT_USER]: StrictEmptyPayload;
}

interface BroadcastEventPayloads {
  [BROADCAST_EVENT.STATE]: StatePayload;
  [BROADCAST_EVENT.TIMER]: TimerPayload;
}

declare module "phoenix" {
  interface Channel {
    push<T extends PushEvent>(
      event: T,
      payload: PushEventPayloads[T],
      timeout?: number,
    ): Push;
    on<T extends BroadcastEvent>(
      event: T,
      callback: (payload: BroadcastEventPayloads[T]) => void,
    ): number;
    off(event: BroadcastEvent, ref?: number): void;
  }
}
