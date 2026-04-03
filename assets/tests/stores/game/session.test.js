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
      advanceTurn: vi.fn(),
      makeAssumption: vi.fn(),
      startPlayback: vi.fn(),
      pausePlayback: vi.fn(),
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
        events: {
          state: expect.any(Function),
        },
        commands: expect.objectContaining({
          startGame: expect.objectContaining({
            event: "start_game",
          }),
          advanceTurn: expect.objectContaining({
            event: "advance_turn",
          }),
          makeAssumption: expect.objectContaining({
            event: "make_assumption",
          }),
          startPlayback: expect.objectContaining({
            event: "start_playback",
          }),
          pausePlayback: expect.objectContaining({
            event: "pause_playback",
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
