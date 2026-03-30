import { render, screen } from "@testing-library/svelte";
import { describe, expect, test, beforeEach, afterEach, vi } from "vitest";
import * as GameContext from "~/contexts/game";
import { currentUser } from "~/stores/scope";
import Score from "~components/score.svelte";

vi.mock("~/stores/scope", async () => {
  const { writable } = await import("svelte/store");

  return {
    currentUser: writable(null),
    provider: writable(undefined),
  };
});

describe("Score", () => {
  let mockGameContext;
  let mockScopeContext;
  let getGameContextSpy;

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

    mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    currentUser.set(mockScopeContext.user);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders score from game context", () => {
    mockGameContext.snapshot.game.scores = { "user-1": 3 };

    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Score);

    expect(
      screen.getByRole("button", { name: "Your score: 3" })
    ).toBeInTheDocument();
    expect(screen.getByText("3")).toBeInTheDocument();
  });

  test("returns 0 when user score is not defined", () => {
    mockGameContext.snapshot.game.scores = { "user-2": 5 };

    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Score);

    expect(screen.getByText("0")).toBeInTheDocument();
  });

  test("returns 0 when scores object is undefined", () => {
    mockGameContext.snapshot.game.scores = undefined;

    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Score);

    expect(screen.getByText("0")).toBeInTheDocument();
  });

  test("updates score when game context changes", () => {
    mockGameContext.snapshot.game.scores = { "user-1": 7 };

    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Score);

    expect(
      screen.getByRole("button", { name: "Your score: 7" })
    ).toBeInTheDocument();

    // Simulating score update by updating the mock and re-rendering
    mockGameContext.snapshot.game.scores = { "user-1": 12 };
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Score);

    expect(
      screen.getByRole("button", { name: "Your score: 12" })
    ).toBeInTheDocument();
    expect(screen.getByText("12")).toBeInTheDocument();
  });
});
