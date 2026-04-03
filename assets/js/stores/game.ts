import type { StatePayload } from "~contracts";
import { createSession } from "~/transport/session";

export interface GameSessionSpec {
  events: {
    state: StatePayload;
  };
  snapshot: StatePayload;
  commands: {
    startGame: {
      event: "start_game";
    };
    advanceTurn: {
      event: "advance_turn";
    };
    makeAssumption: {
      event: "make_assumption";
      payload: {
        position: number;
      };
    };
    startPlayback: {
      event: "start_playback";
    };
    pausePlayback: {
      event: "pause_playback";
    };
  };
}

export function createGameSession(topic: string) {
  return createSession<GameSessionSpec>({
    topic,
    events: {
      state: (_snapshot, payload) => payload,
    },
    commands: {
      startGame: {
        event: "start_game",
      },
      advanceTurn: {
        event: "advance_turn",
      },
      makeAssumption: {
        event: "make_assumption",
      },
      startPlayback: {
        event: "start_playback",
      },
      pausePlayback: {
        event: "pause_playback",
      },
    },
  });
}
