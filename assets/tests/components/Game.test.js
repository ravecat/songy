import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import * as Scope from "~components/Scope.svelte";

import Game from "~components/Game.svelte";

describe("Game", () => {
  let mockChannelContext;
  let getScopeContextSpy;

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
        turn: {
          phase: TURN_PHASE.STEADY,
          queue: ["user-1"],
          cursor: 0,
        },
      },
    };

    getScopeContextSpy = vi.spyOn(Scope, 'getScopeContext');
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
    
    mockChannelContext.state.turn.phase = TURN_PHASE.STEADY;
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext]
      ]),
    });

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

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext]
      ]),
    });

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

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext]
      ]),
    });

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

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext]
      ]),
    });

    // Should render nothing for undefined phase
    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  test("renders nothing when state is undefined", () => {
    const mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };
    
    // Empty state that still has structure for components
    mockChannelContext.state = {
      participants: [],
      turn: undefined,
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext]
      ]),
    });

    // Should render nothing for undefined turn
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

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext]
      ]),
    });

    // Should render nothing for null phase
    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  test("throws error when gameContext is missing", () => {
    expect(() => {
      render(Game, {
        context: new Map(),
      });
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

      render(Game, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext]
        ]),
      });

      expect(screen.queryByText("Alice")).not.toBeInTheDocument();
    }
  );
});
