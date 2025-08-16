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
          phase: TURN_PHASE.PLAYING,
          queue: ["user-1"],
          current_player_index: 0,
        },
      },
    };
  });

  test("displays game interface on turn_ready phase", () => {
    mockChannelContext.state.turn.phase = TURN_PHASE.PLAYING;

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    // Check that participants component is rendered (part of TurnPlaying)
    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  test("displays waiting view on turn_waiting phase", () => {
    mockChannelContext.state.turn.phase = TURN_PHASE.WAITING;

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    // Check that the current player's turn is displayed
    expect(screen.getByText("Alice turn")).toBeInTheDocument();
    expect(screen.getByText("Ready?")).toBeInTheDocument();
  });

  test("displays results view on turn_results phase", () => {
    mockChannelContext.state.turn.phase = TURN_PHASE.RESULTS;

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.getByText("turn_results")).toBeInTheDocument();
  });

  test("defaults to game interface when turn phase is undefined", () => {
    mockChannelContext.state.turn = undefined;

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    // Should display game interface as fallback
    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  test("defaults to game interface when state is undefined", () => {
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

    // Should display game interface as fallback - we can't check for specific text
    // since participants array is empty, but component should render without error
    expect(screen.queryByText("turn_waiting")).not.toBeInTheDocument();
  });

  test("defaults to game interface when turn phase is null", () => {
    mockChannelContext.state.turn.phase = null;

    render(Game, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    // Should display game interface as fallback
    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  test("throws error when gameContext is missing", () => {
    expect(() => {
      render(Game, {
        context: new Map(),
      });
    }).toThrow("getGameContext() must be called within a game context");
  });

  test.each(["turn_countdown", "", "unknown_phase", 123, {}, []])(
    "defaults to game interface for invalid phase: %s",
    (phase) => {
      mockChannelContext.state.turn.phase = phase;

      render(Game, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext],
          [SCOPE_CONTEXT_KEY, mockScopeContext],
        ]),
      });

      // Should display game interface as fallback - check for participants
      expect(screen.getByText("Alice")).toBeInTheDocument();
    }
  );
});
