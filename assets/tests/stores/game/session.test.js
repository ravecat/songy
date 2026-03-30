import { describe, expect, test, vi } from "vitest";

vi.mock("~/socket", async () => {
  const { Socket } = await import("phoenix");

  return {
    default: new Socket("/socket", {}),
  };
});

import { createGameSession } from "~/stores/game.svelte";

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

function buildTransport() {
  let resolveJoin;
  let failureHandler;
  let stateHandler;
  let timerHandler;
  const join = new Promise((resolve) => {
    resolveJoin = resolve;
  });

  return {
    join: vi.fn(() => join),
    onFailure: vi.fn((callback) => {
      failureHandler = callback;
      return vi.fn();
    }),
    subscribe: vi.fn((event, callback) => {
      if (event === "state") {
        stateHandler = callback;
      }

      if (event === "timer") {
        timerHandler = callback;
      }

      return vi.fn();
    }),
    push: vi.fn(),
    dispose: vi.fn(),
    resolveJoinOk(payload) {
      resolveJoin({
        status: "ok",
        response: payload,
      });
    },
    resolveJoinError(response) {
      resolveJoin({
        status: "error",
        response,
      });
    },
    resolveJoinTimeout() {
      resolveJoin({
        status: "timeout",
      });
    },
    emitSnapshot(payload) {
      stateHandler(payload);
    },
    emitTimer(remaining) {
      timerHandler({ remaining });
    },
    emitTransportError(error) {
      failureHandler({
        kind: "error",
        error,
      });
    },
    emitTransportClose() {
      failureHandler({
        kind: "close",
      });
    },
  };
}

describe("createGameSession", () => {
  test("starts in connecting state", () => {
    const session = createGameSession({ transport: buildTransport() });

    expect(session.state).toBeNull();
    expect(session.connection).toBe("connecting");
    expect(session.error).toBeNull();
  });

  test("subscribes to transport immediately", () => {
    const transport = buildTransport();

    createGameSession({ transport });

    expect(transport.join).toHaveBeenCalledTimes(1);
    expect(transport.onFailure).toHaveBeenCalledTimes(1);
    expect(transport.subscribe).toHaveBeenNthCalledWith(
      1,
      "state",
      expect.any(Function),
    );
    expect(transport.subscribe).toHaveBeenNthCalledWith(
      2,
      "timer",
      expect.any(Function),
    );
  });

  test("maps join snapshot into the public session", async () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });
    const payload = buildStatePayload();

    transport.resolveJoinOk(payload);
    await Promise.resolve();

    expect(session.state).toStrictEqual(payload);
    expect(session.game).toStrictEqual(payload.game);
    expect(session.permissions).toStrictEqual(payload.permissions);
    expect(session.connection).toBe("ready");
  });

  test("maps transport snapshot and timer into the public session", () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });
    const payload = buildStatePayload();

    transport.emitSnapshot(payload);
    transport.emitTimer(9);

    expect(session.state).toStrictEqual(payload);
    expect(session.game).toStrictEqual(payload.game);
    expect(session.permissions).toStrictEqual(payload.permissions);
    expect(session.timer).toBe(9);
    expect(session.connection).toBe("ready");
  });

  test("keeps timer during challenging phase", () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });

    transport.emitTimer(12);
    transport.emitSnapshot(buildStatePayload("challenging"));

    expect(session.timer).toBe(12);
  });

  test("clears timer when snapshot phase is not challenging", () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });

    transport.emitTimer(12);
    transport.emitSnapshot(buildStatePayload("results"));

    expect(session.timer).toBeNull();
  });

  test("maps recoverable failure after snapshot to reconnecting", () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });
    const error = new Error("channel closed");

    transport.emitSnapshot(buildStatePayload());
    transport.emitTransportError(error);

    expect(session.connection).toBe("reconnecting");
    expect(session.error).toBe(error);
  });

  test("maps transport failure before first snapshot to error", () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });
    const error = new Error("join rejected");

    transport.emitTransportError(error);

    expect(session.connection).toBe("error");
    expect(session.error).toBe(error);
  });

  test("maps join rejection before first snapshot to error", async () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });
    const error = { reason: "game_not_found" };

    transport.resolveJoinError(error);
    await Promise.resolve();

    expect(session.connection).toBe("error");
    expect(session.error).toEqual(error);
  });

  test("maps join timeout before first snapshot to error", async () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });

    transport.resolveJoinTimeout();
    await Promise.resolve();

    expect(session.connection).toBe("error");
    expect(session.error).toEqual(new Error("Connection timed out"));
  });

  test("delegates commands to the transport", async () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });

    transport.push.mockResolvedValueOnce(undefined);
    transport.push.mockResolvedValueOnce({
      status: "ok",
      response: { token: "test-token" },
    });

    await expect(session.startGame()).resolves.toBeUndefined();
    await expect(session.getProvider()).resolves.toEqual({
      token: "test-token",
    });

    expect(transport.push).toHaveBeenNthCalledWith(1, "start_game", {});
    expect(transport.push).toHaveBeenNthCalledWith(2, "get_provider", {});
  });

  test("disposes projection and transport only once", () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });

    session.dispose();
    session.dispose();

    expect(session.connection).toBe("closed");
    expect(transport.dispose).toHaveBeenCalledTimes(1);
  });
});
