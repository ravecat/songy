import { render, screen } from "@testing-library/svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import Timer from "~components/timer.svelte";
import GameContextFixture from "../fixtures/game_context_fixture.svelte";

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
    status: "ready",
    error: null,
    commands: {
      startGame: vi.fn(),
      advanceTurn: vi.fn(),
      makeAssumption: vi.fn(),
      startPlayback: vi.fn(),
      pausePlayback: vi.fn(),
    },
    dispose: vi.fn(),
  };
}

describe("Timer", () => {
  function renderWithSession(session) {
    return render(GameContextFixture, {
      component: Timer,
      session,
    });
  }

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  test("does not render outside the challenging phase", () => {
    renderWithSession(buildSession("ready"));

    expect(screen.queryByRole("timer")).not.toBeInTheDocument();
  });

  test("renders remaining seconds", () => {
    renderWithSession(buildSession());

    expect(screen.getByRole("timer")).toHaveTextContent("12");
  });

  test("counts down locally from deadline_at_ms", async () => {
    renderWithSession(buildSession());

    vi.advanceTimersByTime(1_000);
    await Promise.resolve();

    expect(screen.getByRole("timer")).toHaveTextContent("11");
  });
});
