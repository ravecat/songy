import { get, writable } from "svelte/store";
import { beforeEach, describe, expect, test, vi } from "vitest";

vi.mock("~/transport/session", () => ({
  createSession: vi.fn(),
}));

import { createGameSession } from "~/stores/game";
import { createSession } from "~/transport/session";

function buildSessionStore() {
  const initialState = {
    snapshot: null,
    status: "loading",
    error: null,
  };
  const store = writable(initialState);

  return {
    commands: {
      startGame: vi.fn(),
      advanceTurn: vi.fn(() => Promise.resolve()),
      makeAssumption: vi.fn(() => Promise.resolve()),
      startPlayback: vi.fn(() => Promise.resolve()),
      pausePlayback: vi.fn(() => Promise.resolve()),
    },
    setState(nextState) {
      store.set(nextState);
    },
    subscribe: store.subscribe,
  };
}

describe("createGameSession", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test("returns the session store from createSession unchanged", () => {
    const sessionStore = buildSessionStore();

    vi.mocked(createSession).mockReturnValue(sessionStore);

    const session = createGameSession("room:test-room");

    expect(session).toBe(sessionStore);
  });

  test("creates session with the game channel config", () => {
    const sessionStore = buildSessionStore();

    vi.mocked(createSession).mockReturnValue(sessionStore);

    createGameSession("room:test-room");

    expect(createSession).toHaveBeenCalledWith(
      expect.objectContaining({
        topic: "room:test-room",
        connect: expect.objectContaining({
          error: expect.any(Function),
          timeout: expect.any(Function),
        }),
        events: {
          state: expect.any(Function),
        },
        commands: expect.objectContaining({
          startGame: expect.objectContaining({
            event: "start_game",
            payload: expect.any(Function),
          }),
          advanceTurn: expect.objectContaining({
            event: "advance_turn",
            payload: expect.any(Function),
            ok: expect.any(Function),
            error: expect.any(Function),
            timeout: expect.any(Function),
          }),
          makeAssumption: expect.objectContaining({
            event: "make_assumption",
            payload: expect.any(Function),
            ok: expect.any(Function),
            error: expect.any(Function),
            timeout: expect.any(Function),
          }),
          startPlayback: expect.objectContaining({
            event: "start_playback",
            payload: expect.any(Function),
            ok: expect.any(Function),
            error: expect.any(Function),
            timeout: expect.any(Function),
          }),
          pausePlayback: expect.objectContaining({
            event: "pause_playback",
            payload: expect.any(Function),
            ok: expect.any(Function),
            error: expect.any(Function),
            timeout: expect.any(Function),
          }),
        }),
      }),
    );
  });

  test("keeps the generic store state shape", () => {
    const sessionStore = buildSessionStore();
    const payload = { id: "state-1" };

    vi.mocked(createSession).mockReturnValue(sessionStore);

    const session = createGameSession("room:test-room");

    sessionStore.setState({
      snapshot: payload,
      status: "ready",
      error: null,
    });

    expect(get(session)).toEqual({
      snapshot: payload,
      status: "ready",
      error: null,
    });
  });

  test("passes through generic session errors unchanged", () => {
    const sessionStore = buildSessionStore();
    const error = {
      kind: "connect_error",
      cause: {
        reason: "game_not_found",
      },
    };

    vi.mocked(createSession).mockReturnValue(sessionStore);

    const session = createGameSession("room:test-room");

    sessionStore.setState({
      snapshot: null,
      status: "failed",
      error,
    });

    expect(get(session).error).toEqual(error);
  });
});
