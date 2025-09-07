import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import { SCOPE_CONTEXT_KEY } from "~components/Scope.svelte";

import Game from "~components/Game.svelte";

describe("Game", () => {
  let mockChannelContext;
  let mockScopeContext;

  beforeEach(() => {
    mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };

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
  });

  test("displays game interface on ready phase", () => {
    mockChannelContext.state.turn.phase = TURN_PHASE.STEADY;

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  test("displays waiting view on waiting phase", () => {
    mockChannelContext.state.turn.phase = TURN_PHASE.WAITING;
    mockScopeContext.user = {
      uuid: "user-1",
      name: "Alice",
    };

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.getByText("Alice turn")).toBeInTheDocument();
    expect(screen.getByText("Ready?")).toBeInTheDocument();
  });

  test("displays results view on results phase", () => {
    mockChannelContext.state.turn.phase = TURN_PHASE.RESULTS;

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  test("renders nothing when turn phase is undefined", () => {
    mockChannelContext.state.turn = undefined;

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    // Should render nothing for undefined phase
    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  test("renders nothing when state is undefined", () => {
    // Empty state that still has structure for components
    mockChannelContext.state = {
      participants: [],
      turn: undefined,
    };

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    // Should render nothing for undefined turn
    expect(screen.queryByText("waiting")).not.toBeInTheDocument();
    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  test("renders nothing when turn phase is null", () => {
    mockChannelContext.state.turn.phase = null;

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
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
      mockChannelContext.state.turn.phase = phase;

      render(Game, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext],
          [SCOPE_CONTEXT_KEY, mockScopeContext],
        ]),
      });

      expect(screen.queryByText("Alice")).not.toBeInTheDocument();
    }
  );
});
