import { describe, expect, test } from "vitest";
import {
  createSessionCore,
  createSongySessionState,
  createGameSessionState,
} from "~shared/game_session.migrate";

function buildStatePayload(phase = "challenging") {
  return {
    game: {
      id: "game-1",
      owner_id: "owner-1",
      max_participants: 8,
      max_score: 10,
      status: "in_progress",
      participants: {},
      scores: {},
      player: null,
      timelines: {},
      created_at: "2026-01-01T00:00:00Z",
      queue: [],
      cursor: 0,
      track: null,
      turn: {
        phase,
        assumptions: {},
        winner_id: null,
      },
    },
    permissions: {
      can_control_playback: false,
      can_advance_turn: false,
      can_start_game: false,
      can_start_turn: false,
      can_restart_game: false,
      can_see_assumptions: false,
      can_make_assumptions: false,
    },
  };
}

describe("createSessionCore", () => {
  test("starts in connecting state", () => {
    const state = createSessionCore();

    expect(state.snapshot).toBeNull();
    expect(state.connection).toBe("connecting");
    expect(state.error).toBeNull();
  });

  test("applies snapshot generically", () => {
    const state = createSessionCore();
    const payload = { value: 1 };

    state.applySnapshot(payload);

    expect(state.snapshot).toBe(payload);
    expect(state.connection).toBe("ready");
    expect(state.error).toBeNull();
  });

  test("moves to error before first snapshot", () => {
    const state = createSessionCore();
    const error = new Error("join failed");

    state.applyFailure(error);

    expect(state.connection).toBe("error");
    expect(state.error).toBe(error);
  });

  test("moves to reconnecting after ready", () => {
    const state = createSessionCore();
    const error = new Error("channel closed");

    state.applySnapshot({ value: 1 });
    state.applyFailure(error);

    expect(state.connection).toBe("reconnecting");
    expect(state.error).toBe(error);
  });

  test("ignores failure after close", () => {
    const state = createSessionCore();

    state.close();
    state.applyFailure(new Error("ignored"));

    expect(state.connection).toBe("closed");
    expect(state.error).toBeNull();
  });
});

describe("createSongySessionState", () => {
  test("exposes songy selectors over the snapshot", () => {
    const state = createSongySessionState();
    const payload = buildStatePayload();

    state.applySnapshot(payload);

    expect(state.snapshot).toBe(payload);
    expect(state.game).toBe(payload.game);
    expect(state.permissions).toBe(payload.permissions);
    expect(state.connection).toBe("ready");
    expect(state.error).toBeNull();
  });

  test("keeps timer during challenging phase", () => {
    const state = createSongySessionState();

    state.applyTimer(12);
    state.applySnapshot(buildStatePayload("challenging"));

    expect(state.timer).toBe(12);
  });

  test("clears timer when snapshot phase is not challenging", () => {
    const state = createSongySessionState();

    state.applyTimer(12);
    state.applySnapshot(buildStatePayload("results"));

    expect(state.timer).toBeNull();
  });

  test("keeps compatibility alias", () => {
    const state = createGameSessionState();

    expect(state.game).toBeNull();
    expect(state.timer).toBeNull();
  });
});
