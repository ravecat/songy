import type { StatePayload } from "~contracts";
import { createSession } from "~/transport/store";

export interface GameSessionSpec {
  events: {
    state: StatePayload;
  };
  snapshot: StatePayload;
}

export function createGameSession(topic: string) {
  return createSession<GameSessionSpec>({
    topic,
    events: {
      state: (_snapshot, payload) => payload,
    },
  }).extend(({ push }) => ({
    startGame() {
      push("start_game", {});
    },
    advanceTurn() {
      push("advance_turn", {});
    },
    makeAssumption(position: number) {
      push("make_assumption", { position });
    },
    startPlayback() {
      push("start_playback", {});
    },
    pausePlayback() {
      push("pause_playback", {});
    },
  }));
}
