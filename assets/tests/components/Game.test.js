import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import * as GameContext from "~components/GameContext.svelte";
import * as Scope from "~components/Scope.svelte";

import Game from "~components/Game.svelte";

describe("Game", () => {
  let mockChannelContext;
  let getScopeContextSpy;
  let getGameContextSpy;

  beforeEach(() => {
    mockChannelContext = {
      state: {
        participants: [
          {
            uuid: "user-1",
            name: "Alice",
            avatar_url: "https://example.com/alice.jpg",
          },
        ],
        queue: ["user-1"],
        cursor: 0,
        turn: {
          phase: TURN_PHASE.READY,
        },
      },
    };

    getScopeContextSpy = vi.spyOn(Scope, "getScopeContext");
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("displays game interface on ready phase", () => {
    const mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };

    mockChannelContext.state.turn.phase = TURN_PHASE.READY;

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  test("displays waiting view on waiting phase", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    mockChannelContext.state.turn.phase = TURN_PHASE.WAITING;

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.getByText("It's your turn")).toBeInTheDocument();
    expect(screen.getByText("Ready?")).toBeInTheDocument();
  });

  test("displays results view on results phase", () => {
    const mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };

    mockChannelContext.state.turn.phase = TURN_PHASE.RESULTS;

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  test("renders nothing when turn phase is undefined", () => {
    const mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };

    mockChannelContext.state.turn = undefined;

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  test("renders nothing when state is undefined", () => {
    const mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };

    mockChannelContext.state = {
      participants: [],
      turn: undefined,
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.queryByText("waiting")).not.toBeInTheDocument();
    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  test("renders nothing when turn phase is null", () => {
    const mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };

    mockChannelContext.state.turn.phase = null;

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  test("throws error when gameContext is missing", () => {
    getGameContextSpy.mockImplementation(() => {
      throw new Error("getGameContext() must be called within a game context");
    });

    expect(() => {
      render(Game);
    }).toThrow("getGameContext() must be called within a game context");
  });

  test.each(["turn_countdown", "", "unknown_phase", 123, {}, []])(
    "renders nothing for invalid phase: %s",
    (phase) => {
      const mockScopeContext = {
        user: {
          uuid: "test-user-uuid",
          name: "Test User",
        },
      };

      mockChannelContext.state.turn.phase = phase;

      getScopeContextSpy.mockReturnValue(mockScopeContext);
      getGameContextSpy.mockReturnValue(mockChannelContext);

      render(Game);

      expect(screen.queryByText("Alice")).not.toBeInTheDocument();
    }
  );
});
