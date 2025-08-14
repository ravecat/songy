import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";

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
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    // Check that participants component is rendered (part of TurnPlaying)
    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  test("displays waiting view on turn_waiting phase", () => {
    mockChannelContext.state.turn.phase = TURN_PHASE.WAITING;

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    // Check that the current player's turn is displayed
    expect(screen.getByText("Alice turn")).toBeInTheDocument();
    expect(screen.getByText("Ready?")).toBeInTheDocument();
  });

  test("displays challenge view on turn_challenging phase", () => {
    mockChannelContext.state.turn.phase = TURN_PHASE.CHALLENGING;

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(screen.getByText("turn_challenging")).toBeInTheDocument();
  });

  test("displays results view on turn_results phase", () => {
    mockChannelContext.state.turn.phase = TURN_PHASE.RESULTS;

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(screen.getByText("turn_results")).toBeInTheDocument();
  });

  test("defaults to game interface when turn phase is undefined", () => {
    mockChannelContext.state.turn = undefined;

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
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
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
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
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    // Should display game interface as fallback
    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  test("throws error when channel context is missing", () => {
    expect(() => {
      render(Game, {
        context: new Map(),
      });
    }).toThrow("getChannelContext() must be called within a Channel component");
  });

  test("displays correct view for each game phase", () => {
    const phases = [
      { phase: TURN_PHASE.PLAYING, expectedText: "Alice" }, // Game interface shows participants
      { phase: TURN_PHASE.WAITING, expectedText: "Alice turn" }, // Waiting view shows player turn
      { phase: TURN_PHASE.CHALLENGING, expectedText: "turn_challenging" }, // Stub component
      { phase: TURN_PHASE.RESULTS, expectedText: "turn_results" }, // Stub component
    ];

    phases.forEach(({ phase, expectedText }) => {
      mockChannelContext.state.turn.phase = phase;

      const { unmount } = render(Game, {
        context: new Map([
          ["channel", mockChannelContext],
          ["scope", mockScopeContext],
        ]),
      });

      expect(screen.getByText(expectedText)).toBeInTheDocument();
      unmount();
    });
  });

  test.each(["turn_countdown", "", "unknown_phase", 123, {}, []])(
    "defaults to game interface for invalid phase: %s",
    (phase) => {
      mockChannelContext.state.turn.phase = phase;

      render(Game, {
        context: new Map([
          ["channel", mockChannelContext],
          ["scope", mockScopeContext],
        ]),
      });

      // Should display game interface as fallback - check for participants
      expect(screen.getByText("Alice")).toBeInTheDocument();
    }
  );
});
