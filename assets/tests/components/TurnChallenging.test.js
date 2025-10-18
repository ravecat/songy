import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import * as GameContext from "~components/GameContext.svelte";
import * as Scope from "~components/Scope.svelte";

import TurnChallenging from "~components/TurnChallenging.svelte";

describe("TurnChallenging", () => {
  let mockChannelContext;
  let mockParticipants;
  let getScopeContextSpy;
  let getGameContextSpy;

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

    getScopeContextSpy = vi.spyOn(Scope, 'getScopeContext');
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("when current user is NOT the active player (challenger)", () => {
    test("displays participants and current track components", () => {
      const mockScopeContext = {
        user: {
          uuid: "user-2", // Bob is current user
          name: "Bob",
        },
      };
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);
      
      getGameContextSpy.mockReturnValue(mockChannelContext);
        render(TurnChallenging);

      // Should show all participants
      expect(screen.getByText("Alice")).toBeInTheDocument();
      expect(screen.getByText("Bob")).toBeInTheDocument();
      expect(screen.getByText("Charlie")).toBeInTheDocument();

      const timelines = screen.getAllByRole("list");
      expect(timelines.length).toBeGreaterThanOrEqual(1);
    });

    test("shows participants and timeline when user is third in queue", () => {
      const thirdUserContext = {
        user: {
          uuid: "user-3", // Charlie is current user
          name: "Charlie",
        },
      };
      
      getScopeContextSpy.mockReturnValue(thirdUserContext);

      getGameContextSpy.mockReturnValue(mockChannelContext);
        render(TurnChallenging);

      // Should show all participants
      expect(screen.getByText("Alice")).toBeInTheDocument();
      expect(screen.getByText("Bob")).toBeInTheDocument();
      expect(screen.getByText("Charlie")).toBeInTheDocument();

      const timelines = screen.getAllByRole("list");
      expect(timelines.length).toBeGreaterThanOrEqual(1);
    });

    test("shows participants and timeline when active player changes to different user", () => {
      const mockScopeContext = {
        user: {
          uuid: "user-2", // Bob is still current user
          name: "Bob",
        },
      };
      
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
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);

      getGameContextSpy.mockReturnValue(differentActivePlayerContext);
        render(TurnChallenging);

      expect(screen.getByText("Alice")).toBeInTheDocument();
      expect(screen.getByText("Bob")).toBeInTheDocument();
      expect(screen.getByText("Charlie")).toBeInTheDocument();

      const timelines = screen.getAllByRole("list");
      expect(timelines.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe("when current user IS the active player", () => {
    test("displays participants and player components when user is active player", () => {
      // Make current user the active player
      const activeUserContext = {
        user: {
          uuid: "user-1", // Alice is both current user and active player
          name: "Alice",
        },
      };
      
      getScopeContextSpy.mockReturnValue(activeUserContext);

      getGameContextSpy.mockReturnValue(mockChannelContext);
        render(TurnChallenging);

      // Should show participants component
      expect(screen.getByText("Alice")).toBeInTheDocument();
      expect(screen.getByText("Bob")).toBeInTheDocument();
      expect(screen.getByText("Charlie")).toBeInTheDocument();

      // Should show player controls (play/pause button from Player component)
      const playerButton = screen.getByRole("button", {
        name: /play track|pause track/i,
      });
      expect(playerButton).toBeInTheDocument();
    });

    test("displays participants and player when active player index changes to current user", () => {
      const mockScopeContext = {
        user: {
          uuid: "user-2", // Bob is current user
          name: "Bob",
        },
      };
      
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
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);

      getGameContextSpy.mockReturnValue(bobActiveContext);
        render(TurnChallenging);

      // Should show participants component
      expect(screen.getByText("Alice")).toBeInTheDocument();
      expect(screen.getByText("Bob")).toBeInTheDocument();
      expect(screen.getByText("Charlie")).toBeInTheDocument();

      // Should show player controls (play/pause button from Player component)
      const playerButton = screen.getByRole("button", {
        name: /play track|pause track/i,
      });
      expect(playerButton).toBeInTheDocument();
    });
  });

  describe("edge cases", () => {
    test("handles missing active player gracefully", () => {
      const mockScopeContext = {
        user: {
          uuid: "user-2",
          name: "Bob",
        },
      };
      
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
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);

      // Should not crash when activePlayer is undefined
      expect(() => {
        getGameContextSpy.mockReturnValue(noActivePlayerContext);
        render(TurnChallenging);
      }).not.toThrow();
    });

    test("handles empty queue gracefully", () => {
      const mockScopeContext = {
        user: {
          uuid: "user-2",
          name: "Bob",
        },
      };
      
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
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);

      expect(() => {
        getGameContextSpy.mockReturnValue(emptyQueueContext);
        render(TurnChallenging);
      }).not.toThrow();
    });

    test("handles missing turn state gracefully", () => {
      const mockScopeContext = {
        user: {
          uuid: "user-2",
          name: "Bob",
        },
      };
      
      const noTurnContext = {
        state: {
          participants: mockParticipants,
          turn: null,
        },
      };
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);

      expect(() => {
        getGameContextSpy.mockReturnValue(noTurnContext);
        render(TurnChallenging);
      }).not.toThrow();
    });
  });

  describe("required contexts", () => {
    test("throws error when gameContext is missing", () => {
      const mockScopeContext = {
        user: {
          uuid: "user-2",
          name: "Bob",
        },
      };
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);
      
      expect(() => {
        render(TurnChallenging);
      }).toThrow();
    });

    test("throws error when scope context is missing", () => {
      getScopeContextSpy.mockImplementation(() => {
        throw new Error("missing_context");
      });
      
      expect(() => {
        getGameContextSpy.mockReturnValue(mockChannelContext);
        render(TurnChallenging);
      }).toThrow("missing_context");
    });

    test("renders without error when both contexts are provided", () => {
      const mockScopeContext = {
        user: {
          uuid: "user-2",
          name: "Bob",
        },
      };
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);
      
      expect(() => {
        getGameContextSpy.mockReturnValue(mockChannelContext);
        render(TurnChallenging);
      }).not.toThrow();
    });
  });
});
