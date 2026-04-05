import { writable } from "svelte/store";
import { render } from "vitest-browser-svelte";
import { describe, expect, test, beforeEach, afterEach, vi } from "vitest";
import { currentUser } from "~/stores/scope";
import Score from "~components/score.svelte";
import { getGameContext } from "~/contexts/game";

vi.mock("~/contexts/game");

vi.mock("~/stores/scope", async () => {
  const { writable } = await import("svelte/store");

  return {
    currentUser: writable(null),
    provider: writable(undefined),
  };
});

describe("Score", () => {
  let mockGameContext;

  beforeEach(() => {
    vi.clearAllMocks();

    mockGameContext = {
      snapshot: {
        game: {
          scores: {},
        },
        permissions: null,
        timer: null,
      },
    };

    currentUser.set({
      uuid: "user-1",
      name: "Alice",
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders score from game context", async () => {
    mockGameContext.snapshot.game.scores = { "user-1": 3 };

    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...mockGameContext,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(Score);

    await expect
      .element(screen.getByRole("button", { name: "Your score: 3" }))
      .toBeVisible();
    await expect.element(screen.getByText("3")).toBeVisible();
  });

  test("returns 0 when user score is not defined", async () => {
    mockGameContext.snapshot.game.scores = { "user-2": 5 };

    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...mockGameContext,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(Score);

    await expect.element(screen.getByText("0")).toBeVisible();
  });

  test("returns 0 when scores object is undefined", async () => {
    mockGameContext.snapshot.game.scores = undefined;

    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...mockGameContext,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(Score);

    await expect.element(screen.getByText("0")).toBeVisible();
  });

  test("updates score when game context changes", async () => {
    const session = writable({
      snapshot: {
        game: {
          scores: { "user-1": 7 },
        },
        permissions: null,
        timer: null,
      },
    });

    vi.mocked(getGameContext).mockReturnValue(session);

    const screen = render(Score);

    await expect
      .element(screen.getByRole("button", { name: "Your score: 7" }))
      .toBeVisible();

    session.set({
      snapshot: {
        game: {
          scores: { "user-1": 12 },
        },
        permissions: null,
        timer: null,
      },
      status: "ready",
      error: null,
    });

    await expect
      .element(screen.getByRole("button", { name: "Your score: 12" }))
      .toBeVisible();
    await expect.element(screen.getByText("12")).toBeVisible();
  });
});
