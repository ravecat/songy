import type { SnapshotPayload } from "~contracts";
import { createSession } from "~/transport/store";

export interface GameSessionSpec {
  events: {
    snapshot: SnapshotPayload;
  };
  snapshot: SnapshotPayload;
}

export function createGameSession(topic: string) {
  return createSession<GameSessionSpec>({
    topic,
    events: {
      snapshot: (_snapshot, payload) => payload,
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
