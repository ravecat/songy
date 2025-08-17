import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import { SCOPE_CONTEXT_KEY } from "~components/Scope.svelte";

import TurnChallenging from "~components/TurnChallenging.svelte";

describe("TurnChallenging", () => {
  let mockChannelContext;
  let mockScopeContext;
  let mockParticipants;

  beforeEach(() => {
    mockParticipants = [
      {
        uuid: "user-1",
        name: "Alice",
        avatar_url: "https://example.com/alice.jpg",
      },
      {
        uuid: "user-2",
        name: "Bob",
        avatar_url: "https://example.com/bob.jpg",
      },
      {
        uuid: "user-3",
        name: "Charlie",
        avatar_url: "https://example.com/charlie.jpg",
      },
    ];

    mockChannelContext = {
      state: {
        participants: mockParticipants,
        turn: {
          phase: TURN_PHASE.CHALLENGING,
          queue: ["user-1", "user-2", "user-3"],
          cursor: 0, // Alice is active player
        },
      },
    };

    mockScopeContext = {
      user: {
        uuid: "user-2", // Bob is current user
        name: "Bob",
      },
    };
  });

  describe("when current user is NOT the active player", () => {
    test("displays challenge view instead of game components", () => {
      render(TurnChallenging, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext],
          [SCOPE_CONTEXT_KEY, mockScopeContext],
        ]),
      });

      expect(screen.getByText("Challenge view")).toBeInTheDocument();
    });

    test("shows challenge view when user is third in queue", () => {
      const thirdUserContext = {
        user: {
          uuid: "user-3", // Charlie is current user
          name: "Charlie",
        },
      };

      render(TurnChallenging, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext],
          [SCOPE_CONTEXT_KEY, thirdUserContext],
        ]),
      });

      expect(screen.getByText("Challenge view")).toBeInTheDocument();
    });

    test("shows challenge view when active player changes to different user", () => {
      // Change active player to user-3 (Charlie)
      const differentActivePlayerContext = {
        state: {
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            queue: ["user-1", "user-2", "user-3"],
            cursor: 2, // Charlie is now active
          },
        },
      };

      render(TurnChallenging, {
        context: new Map([
          [GAME_CONTEXT_KEY, differentActivePlayerContext],
          [SCOPE_CONTEXT_KEY, mockScopeContext], // Bob is still current user
        ]),
      });

      expect(screen.getByText("Challenge view")).toBeInTheDocument();
    });
  });

  describe("when current user IS the active player", () => {
    test("displays game components when user is active player", () => {
      // Make current user the active player
      const activeUserContext = {
        user: {
          uuid: "user-1", // Alice is both current user and active player
          name: "Alice",
        },
      };

      render(TurnChallenging, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext],
          [SCOPE_CONTEXT_KEY, activeUserContext],
        ]),
      });

      // Should show participants component (Alice name appears)
      expect(screen.getByText("Alice")).toBeInTheDocument();
      expect(screen.getByText("Bob")).toBeInTheDocument();
      expect(screen.getByText("Charlie")).toBeInTheDocument();

      // Should NOT show challenge view
      expect(screen.queryByText("Challenge view")).not.toBeInTheDocument();
    });

    test("displays game components when active player index changes to current user", () => {
      // Make Bob the active player
      const bobActiveContext = {
        state: {
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            queue: ["user-1", "user-2", "user-3"],
            cursor: 1, // Bob is now active
          },
        },
      };

      render(TurnChallenging, {
        context: new Map([
          [GAME_CONTEXT_KEY, bobActiveContext],
          [SCOPE_CONTEXT_KEY, mockScopeContext], // Bob is current user
        ]),
      });

      // Should show participants component
      expect(screen.getByText("Alice")).toBeInTheDocument();
      expect(screen.getByText("Bob")).toBeInTheDocument();
      expect(screen.getByText("Charlie")).toBeInTheDocument();

      // Should NOT show challenge view
      expect(screen.queryByText("Challenge view")).not.toBeInTheDocument();
    });
  });

  describe("edge cases", () => {
    test("handles missing active player gracefully", () => {
      const noActivePlayerContext = {
        state: {
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            queue: ["user-1", "user-2", "user-3"],
            cursor: 99, // Invalid index
          },
        },
      };

      // Should not crash when activePlayer is undefined
      expect(() => {
        render(TurnChallenging, {
          context: new Map([
            [GAME_CONTEXT_KEY, noActivePlayerContext],
            [SCOPE_CONTEXT_KEY, mockScopeContext],
          ]),
        });
      }).not.toThrow();
    });

    test("handles empty queue gracefully", () => {
      const emptyQueueContext = {
        state: {
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            queue: [],
            cursor: 0,
          },
        },
      };

      expect(() => {
        render(TurnChallenging, {
          context: new Map([
            [GAME_CONTEXT_KEY, emptyQueueContext],
            [SCOPE_CONTEXT_KEY, mockScopeContext],
          ]),
        });
      }).not.toThrow();
    });

    test("handles missing turn state gracefully", () => {
      const noTurnContext = {
        state: {
          participants: mockParticipants,
          turn: null,
        },
      };

      expect(() => {
        render(TurnChallenging, {
          context: new Map([
            [GAME_CONTEXT_KEY, noTurnContext],
            [SCOPE_CONTEXT_KEY, mockScopeContext],
          ]),
        });
      }).not.toThrow();
    });
  });

  describe("required contexts", () => {
    test("throws error when gameContext is missing", () => {
      expect(() => {
        render(TurnChallenging, {
          context: new Map([[SCOPE_CONTEXT_KEY, mockScopeContext]]),
        });
      }).toThrow();
    });

    test("throws error when scope context is missing", () => {
      expect(() => {
        render(TurnChallenging, {
          context: new Map([[GAME_CONTEXT_KEY, mockChannelContext]]),
        });
      }).toThrow();
    });

    test("renders without error when both contexts are provided", () => {
      expect(() => {
        render(TurnChallenging, {
          context: new Map([
            [GAME_CONTEXT_KEY, mockChannelContext],
            [SCOPE_CONTEXT_KEY, mockScopeContext],
          ]),
        });
      }).not.toThrow();
    });
  });
});
