import { render, screen } from "@testing-library/svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import Timer from "~components/timer.svelte";
import GameContextFixture from "../fixtures/game_context_fixture.svelte";

describe("Timer", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  test("does not render outside the challenging phase", () => {
    render(GameContextFixture, {
      component: Timer,
      session: {
        snapshot: {
          game: {
            turn: {
              phase: "ready",
              deadline_at_ms: null,
            },
          },
        },
      },
    });

    expect(screen.queryByRole("timer")).not.toBeInTheDocument();
  });

  test("renders remaining seconds", () => {
    render(GameContextFixture, {
      component: Timer,
      session: {
        snapshot: {
          game: {
            turn: {
              phase: "challenging",
              deadline_at_ms: Date.now() + 12_000,
            },
          },
        },
      },
    });

    expect(screen.getByRole("timer")).toHaveTextContent("12");
  });

  test("counts down locally from deadline_at_ms", async () => {
    render(GameContextFixture, {
      component: Timer,
      session: {
        snapshot: {
          game: {
            turn: {
              phase: "challenging",
              deadline_at_ms: Date.now() + 12_000,
            },
          },
        },
      },
    });

    vi.advanceTimersByTime(1_000);
    await Promise.resolve();

    expect(screen.getByRole("timer")).toHaveTextContent("11");
  });
});
