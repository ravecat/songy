import { render, screen } from "@testing-library/svelte";
import { writable } from "svelte/store";
import { beforeEach, describe, expect, test, vi } from "vitest";

vi.mock("~/stores/game", () => ({
  createGameSession: vi.fn(),
}));

import GameProviderFixture from "../fixtures/game_provider_fixture.svelte";
import { createGameSession } from "~/stores/game";

function buildStatePayload() {
  return {
    game: {
      id: "game-1",
      owner_id: "owner-1",
      max_participants: 8,
      max_score: 10,
      status: "waiting",
      participants: {},
      scores: {},
      player: null,
      timelines: {},
      created_at: "2026-01-01T00:00:00Z",
      queue: [],
      cursor: 0,
      track: null,
      turn: null,
    },
    permissions: {
      can_control_playback: false,
      can_advance_turn: false,
      can_start_game: true,
      can_start_turn: false,
      can_restart_game: false,
      can_see_assumptions: false,
      can_make_assumptions: false,
    },
  };
}

function createMockSession(initialState = {
  snapshot: null,
  status: "loading",
  error: null,
}) {
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

describe("GameProvider", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test("creates a game session for the provided topic", () => {
    vi.mocked(createGameSession).mockReturnValue(createMockSession());

    render(GameProviderFixture, {
      topic: "room:test-room",
    });

    expect(createGameSession).toHaveBeenCalledWith("room:test-room");
  });

  test("passes the created session to children through context", () => {
    const session = createMockSession({
      snapshot: buildStatePayload(),
      status: "ready",
      error: null,
    });
    const onSession = vi.fn();

    vi.mocked(createGameSession).mockReturnValue(session);

    render(GameProviderFixture, {
      topic: "room:test-room",
      onSession,
    });

    expect(screen.getByTestId("game-provider-child")).toBeInTheDocument();
    expect(onSession).toHaveBeenCalledWith(session);
  });

  test("renders loader while the session is loading", () => {
    vi.mocked(createGameSession).mockReturnValue(createMockSession());

    render(GameProviderFixture, {
      topic: "room:test-room",
    });

    expect(screen.getByRole("status", { name: "loading" })).toBeInTheDocument();
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();
  });

  test("renders connect errors with the server reason", () => {
    vi.mocked(createGameSession).mockReturnValue(createMockSession({
      snapshot: null,
      status: "failed",
      error: {
        kind: "connect_error",
        cause: {
          reason: "game_not_found",
        },
      },
    }));

    render(GameProviderFixture, {
      topic: "room:test-room",
    });

    expect(screen.getByRole("alert")).toBeInTheDocument();
    expect(screen.getByText("Room unavailable")).toBeInTheDocument();
    expect(screen.getByText("Reason: game_not_found")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Back home" })).toHaveAttribute(
      "href",
      "/",
    );
  });

  test("renders a generic message for non-connect failures", () => {
    vi.mocked(createGameSession).mockReturnValue(createMockSession({
      snapshot: null,
      status: "failed",
      error: {
        kind: "transport_close",
      },
    }));

    render(GameProviderFixture, {
      topic: "room:test-room",
    });

    expect(screen.getByRole("alert")).toBeInTheDocument();
    expect(screen.getByText("Failed to load game state.")).toBeInTheDocument();
  });
});
