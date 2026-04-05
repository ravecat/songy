import { writable } from "svelte/store";
import { render } from "vitest-browser-svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";

vi.mock("~/contexts/game");

import Timer from "~components/timer.svelte";
import { getGameContext } from "~/contexts/game";

describe("Timer", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  test("does not render outside the challenging phase", async () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        snapshot: {
          game: {
            turn: {
              phase: "ready",
              deadline_at_ms: null,
            },
          },
        },
        status: "ready",
        error: null,
      }),
    );

    const screen = render(Timer);

    await expect.element(screen.getByRole("timer")).not.toBeInTheDocument();
  });

  test("renders remaining seconds", async () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable(
        {
          snapshot: {
            game: {
              turn: {
                phase: "challenging",
                deadline_at_ms: Date.now() + 12_000,
              },
            },
          },
          status: "ready",
          error: null,
        },
      ),
    );

    const screen = render(Timer);

    await expect.element(screen.getByRole("timer")).toHaveTextContent("12");
  });

  test("counts down locally from deadline_at_ms", async () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable(
        {
          snapshot: {
            game: {
              turn: {
                phase: "challenging",
                deadline_at_ms: Date.now() + 12_000,
              },
            },
          },
          status: "ready",
          error: null,
        },
      ),
    );

    const screen = render(Timer);

    const timer = screen.getByRole("timer");

    await expect.element(timer).toHaveTextContent("12");
    await vi.advanceTimersByTimeAsync(1_000);
    await expect.element(timer).toHaveTextContent("11");
  });

  test("reacts to session changes after mount", async () => {
    const sessionStore = writable({
      snapshot: null,
      status: "loading",
      error: null,
    });

    vi.mocked(getGameContext).mockReturnValue(sessionStore);

    const screen = render(Timer);

    await expect.element(screen.getByRole("timer")).not.toBeInTheDocument();

    sessionStore.set({
      snapshot: {
        game: {
          turn: {
            phase: "challenging",
            deadline_at_ms: Date.now() + 8_000,
          },
        },
      },
      status: "ready",
      error: null,
    });

    await expect.element(screen.getByRole("timer")).toHaveTextContent("8");
  });
});
