import { get, writable } from "svelte/store";
import { beforeEach, describe, expect, test, vi } from "vitest";

vi.mock("~/transport/store", () => ({
  createSession: vi.fn(),
}));

import { createGameSession } from "~/stores/game";
import { createSession } from "~/transport/store";

function buildSessionStore() {
  const initialState = {
    snapshot: null,
    status: "loading",
    error: null,
  };
  const store = writable(initialState);
  const push = vi.fn();
  const sessionStore = {
    push,
    subscribe: store.subscribe,
  };

  return {
    ...sessionStore,
    extend(build) {
      return {
        ...build(sessionStore),
        subscribe: store.subscribe,
      };
    },
    setState(nextState) {
      store.set(nextState);
    },
  };
}

describe("createGameSession", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test("returns the session state with bound actions", () => {
    const sessionStore = buildSessionStore();

    vi.mocked(createSession).mockReturnValue(sessionStore);

    const session = createGameSession("room:test-room");

    expect(session).toEqual(
      expect.objectContaining({
        subscribe: sessionStore.subscribe,
        startGame: expect.any(Function),
        advanceTurn: expect.any(Function),
        makeAssumption: expect.any(Function),
        startPlayback: expect.any(Function),
        pausePlayback: expect.any(Function),
      }),
    );
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
      }),
    );
  });

  test("pushes game actions through the session store", () => {
    const sessionStore = buildSessionStore();

    vi.mocked(createSession).mockReturnValue(sessionStore);

    const session = createGameSession("room:test-room");

    session.startGame();
    session.advanceTurn();
    session.makeAssumption(7);
    session.startPlayback();
    session.pausePlayback();

    expect(sessionStore.push).toHaveBeenNthCalledWith(1, "start_game", {});
    expect(sessionStore.push).toHaveBeenNthCalledWith(2, "advance_turn", {});
    expect(sessionStore.push).toHaveBeenNthCalledWith(3, "make_assumption", {
      position: 7,
    });
    expect(sessionStore.push).toHaveBeenNthCalledWith(4, "start_playback", {});
    expect(sessionStore.push).toHaveBeenNthCalledWith(5, "pause_playback", {});
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
