import { render, screen } from "@testing-library/svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import Timer from "~components/timer.svelte";
import * as GameContext from "~/contexts/game";

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
        deadline_at_ms: phase === "challenging" ? Date.now() + 12_000 : null,
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

function buildSession(phase = "challenging") {
  return {
    snapshot: buildStatePayload(phase),
    connection: "ready",
    error: null,
    startGame: vi.fn(),
    advanceTurn: vi.fn(),
    makeAssumption: vi.fn(),
    startPlayback: vi.fn(),
    pausePlayback: vi.fn(),
    dispose: vi.fn(),
  };
}

describe("Timer", () => {
  let getGameContextSpy;

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  test("does not render outside the challenging phase", () => {
    getGameContextSpy.mockReturnValue(buildSession("ready"));

    render(Timer);

    expect(screen.queryByRole("timer")).not.toBeInTheDocument();
  });

  test("renders remaining seconds", () => {
    getGameContextSpy.mockReturnValue(buildSession());

    render(Timer);

    expect(screen.getByRole("timer")).toHaveTextContent("12");
  });

  test("counts down locally from deadline_at_ms", async () => {
    getGameContextSpy.mockReturnValue(buildSession());

    render(Timer);

    vi.advanceTimersByTime(1_000);
    await Promise.resolve();

    expect(screen.getByRole("timer")).toHaveTextContent("11");
  });
});
