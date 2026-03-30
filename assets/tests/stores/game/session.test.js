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
        deadline_at_ms: phase === "challenging" ? 1_735_689_600_000 : null,
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

    expect(session.snapshot).toBeNull();
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
  });

  test("maps join snapshot into the public session", async () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });
    const payload = buildStatePayload();

    transport.resolveJoinOk(payload);
    await Promise.resolve();

    expect(session.snapshot).toStrictEqual({
      game: payload.game,
      permissions: payload.permissions,
    });
    expect(session.connection).toBe("ready");
  });

  test("maps transport snapshot into the public session", () => {
    const transport = buildTransport();
    const session = createGameSession({ transport });
    const payload = buildStatePayload();

    transport.emitSnapshot(payload);

    expect(session.snapshot).toStrictEqual({
      game: payload.game,
      permissions: payload.permissions,
    });
    expect(session.connection).toBe("ready");
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
      response: undefined,
    });

    await expect(session.startGame()).resolves.toBeUndefined();
    await expect(session.advanceTurn()).resolves.toBeUndefined();

    expect(transport.push).toHaveBeenNthCalledWith(1, "start_game", {});
    expect(transport.push).toHaveBeenNthCalledWith(2, "advance_turn", {});
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
