import { render, screen } from "@testing-library/svelte";
import { describe, expect, test, beforeEach, afterEach, vi } from "vitest";
import * as GameContext from "~components/game_provider.svelte";
import * as Scope from "~components/scope.svelte";
import Score from "~components/score.svelte";

describe("Score", () => {
  let mockGameContext;
  let mockScopeContext;
  let getGameContextSpy;
  let getScopeContextSpy;

  beforeEach(() => {
    vi.clearAllMocks();

    mockGameContext = {
      game: {
        scores: {},
      },
      permissions: null,
      channel: {
        on: vi.fn(),
        off: vi.fn(),
        push: vi.fn(() => ({ receive: vi.fn() })),
      },
    };

    mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getScopeContextSpy = vi.spyOn(Scope, "getScopeContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders score from game context", () => {
    mockGameContext.game.scores = { "user-1": 3 };

    getGameContextSpy.mockReturnValue(mockGameContext);
    getScopeContextSpy.mockReturnValue(mockScopeContext);

    render(Score);

    expect(
      screen.getByRole("button", { name: "Your score: 3" })
    ).toBeInTheDocument();
    expect(screen.getByText("3")).toBeInTheDocument();
  });

  test("returns 0 when user score is not defined", () => {
    mockGameContext.game.scores = { "user-2": 5 };

    getGameContextSpy.mockReturnValue(mockGameContext);
    getScopeContextSpy.mockReturnValue(mockScopeContext);

    render(Score);

    expect(screen.getByText("0")).toBeInTheDocument();
  });

  test("returns 0 when scores object is undefined", () => {
    mockGameContext.game.scores = undefined;

    getGameContextSpy.mockReturnValue(mockGameContext);
    getScopeContextSpy.mockReturnValue(mockScopeContext);

    render(Score);

    expect(screen.getByText("0")).toBeInTheDocument();
  });

  test("updates score when game context changes", () => {
    mockGameContext.game.scores = { "user-1": 7 };

    getGameContextSpy.mockReturnValue(mockGameContext);
    getScopeContextSpy.mockReturnValue(mockScopeContext);

    render(Score);

    expect(
      screen.getByRole("button", { name: "Your score: 7" })
    ).toBeInTheDocument();

    // Simulating score update by updating the mock and re-rendering
    mockGameContext.game.scores = { "user-1": 12 };
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Score);

    expect(
      screen.getByRole("button", { name: "Your score: 12" })
    ).toBeInTheDocument();
    expect(screen.getByText("12")).toBeInTheDocument();
  });
});
