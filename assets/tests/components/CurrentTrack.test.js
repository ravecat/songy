import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import * as GameContext from "~components/GameChannel.svelte";
import * as Scope from "~components/Scope.svelte";

import CurrentTrack from "~components/CurrentTrack.svelte";

describe("Current track component", () => {
  let mockTrack;
  let mockParticipants;
  let getScopeContextSpy;
  let getGameContextSpy;

  beforeEach(() => {
    mockTrack = {
      id: "track123",
      title: "Test Song",
      artist: "Test Artist",
      year: 2023,
    };

    mockParticipants = [
      { uuid: "user-1", name: "Alice" },
      { uuid: "user-2", name: "Bob" },
      { uuid: "user-3", name: "Charlie" }
    ];

    getScopeContextSpy = vi.spyOn(Scope, 'getScopeContext');
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("in READY phase", () => {
    describe("for active player", () => {
      test("shows current track when player has not made assumption", () => {
        const user = { uuid: "user-1", name: "Alice" };

        const gameState = {
          queue: ["user-1", "user-2", "user-3"],
          cursor: 0,
          track: mockTrack,
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.READY,
            assumptions: []
          }
        };
        
        getScopeContextSpy.mockReturnValue({ user });
        
        getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
        
        expect(screen.getByRole("list")).toBeInTheDocument();
      });

      test("hides current track when player has made assumption", () => {
        const user = { uuid: "user-1", name: "Alice" };

        const gameState = {
          queue: ["user-1", "user-2", "user-3"],
          cursor: 0,
          track: mockTrack,
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.READY,
            assumptions: [{ position: 0, user_id: "user-1" }]
          }
        };
        
        getScopeContextSpy.mockReturnValue({ user });
        
        getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
        
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
      });
    });

    describe("for non-active players", () => {
      test("hides current track regardless of assumption status", () => {
        const user = { uuid: "user-2", name: "Bob" };

        const gameState = {
          queue: ["user-1", "user-2", "user-3"],
          cursor: 0,
          track: mockTrack,
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.READY,
            assumptions: []
          }
        };
        
        getScopeContextSpy.mockReturnValue({ user });
        
        getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
        
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
      });
    });
  });

  describe("in CHALLENGING phase", () => {
    describe("for active player", () => {
      test("hides current track regardless of assumption status", () => {
        const user = { uuid: "user-1", name: "Alice" };

        const gameState = {
          queue: ["user-1", "user-2", "user-3"],
          cursor: 0,
          track: mockTrack,
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            assumptions: []
          }
        };
        
        getScopeContextSpy.mockReturnValue({ user });
        
        getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
        
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
      });
    });

    describe("for challenger players", () => {
      test("shows current track when player has not made assumption", () => {
        const user = { uuid: "user-2", name: "Bob" };

        const gameState = {
          queue: ["user-1", "user-2", "user-3"],
          cursor: 0,
          track: mockTrack,
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            assumptions: []
          }
        };
        
        getScopeContextSpy.mockReturnValue({ user });
        
        getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
        
        expect(screen.getByRole("list")).toBeInTheDocument();
      });

      test("hides current track when player has made assumption", () => {
        const user = { uuid: "user-2", name: "Bob" };

        const gameState = {
          queue: ["user-1", "user-2", "user-3"],
          cursor: 0,
          track: mockTrack,
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            assumptions: [{ position: 0, user_id: "user-2" }]
          }
        };
        
        getScopeContextSpy.mockReturnValue({ user });
        
        getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
        
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
      });

      test("displays track card with question mark to hide track details", () => {
        const user = { uuid: "user-2", name: "Bob" };

        const gameState = {
          queue: ["user-1", "user-2", "user-3"],
          cursor: 0,
          track: mockTrack,
          participants: mockParticipants,
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            assumptions: []
          }
        };
        
        getScopeContextSpy.mockReturnValue({ user });
        
        getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
        
        expect(screen.getByText("?")).toBeInTheDocument();
        expect(screen.queryByText("Test Song")).not.toBeInTheDocument();
        expect(screen.queryByText("Test Artist")).not.toBeInTheDocument();
      });
    });
  });

  describe("in other game phases", () => {
    [TURN_PHASE.WAITING, TURN_PHASE.STEADY, TURN_PHASE.RESULTS].forEach(phase => {
      test(`hides current track in ${phase} phase`, () => {
        const user = { uuid: "user-1", name: "Alice" };

        const gameState = {
          queue: ["user-1", "user-2", "user-3"],
          cursor: 0,
          track: mockTrack,
          participants: mockParticipants,
          turn: {
            phase: phase,
            assumptions: []
          }
        };
        
        getScopeContextSpy.mockReturnValue({ user });
        
        getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
        
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
      });
    });
  });

  describe("with edge cases", () => {
    test("handles missing turn state gracefully", () => {
      const user = { uuid: "user-1", name: "Alice" };
      
      const gameState = { participants: mockParticipants };
      
      getScopeContextSpy.mockReturnValue({ user });
      getGameContextSpy.mockReturnValue({ state: gameState });
      
      expect(() => render(CurrentTrack)).not.toThrow();
      
      expect(screen.queryByRole("list")).not.toBeInTheDocument();
    });

    test("handles empty player queue gracefully", () => {
      const user = { uuid: "user-1", name: "Alice" };

      const gameState = {
        queue: [],
        cursor: 0,
        track: mockTrack,
        participants: mockParticipants,
        turn: {
          phase: TURN_PHASE.READY,
          assumptions: []
        }
      };
      
      getScopeContextSpy.mockReturnValue({ user });
      
      getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
      
      expect(screen.queryByRole("list")).not.toBeInTheDocument();
    });

    test("handles invalid cursor position gracefully", () => {
      const user = { uuid: "user-1", name: "Alice" };

      const gameState = {
        queue: ["user-1", "user-2"],
        cursor: 5, // Invalid cursor
        track: mockTrack,
        participants: mockParticipants,
        turn: {
          phase: TURN_PHASE.READY,
          assumptions: []
        }
      };
      
      getScopeContextSpy.mockReturnValue({ user });
      
      getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
      
      expect(screen.queryByRole("list")).not.toBeInTheDocument();
    });

    test("handles missing track data gracefully", () => {
      const user = { uuid: "user-1", name: "Alice" };

      const gameState = {
        queue: ["user-1", "user-2"],
        cursor: 0,
        track: null,
        participants: mockParticipants,
        turn: {
          phase: TURN_PHASE.READY,
          assumptions: []
        }
      };
      
      getScopeContextSpy.mockReturnValue({ user });
      
      getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
      
      expect(screen.queryByRole("list")).not.toBeInTheDocument();
    });
  });

  describe("with required contexts", () => {
    test("throws error when game context is missing", () => {
      const user = { uuid: "user-1", name: "Alice" };
      
      getScopeContextSpy.mockReturnValue({ user });
      
      expect(() => {
        render(CurrentTrack);
      }).toThrow();
    });

    test("throws error when scope context is missing", () => {
      const gameState = {
        turn: {
          phase: TURN_PHASE.READY,
          queue: ["user-1", "user-2", "user-3"],
          cursor: 0,
          track: mockTrack,
          assumptions: []
        },
        participants: mockParticipants
      };
      
      getScopeContextSpy.mockImplementation(() => {
        throw new Error("missing_context");
      });
      
      expect(() => {
        getGameContextSpy.mockReturnValue({ state: gameState });
        render(CurrentTrack);
      }).toThrow("missing_context");
    });

    test("renders without error when both contexts are provided", () => {
      const user = { uuid: "user-1", name: "Alice" };

      const gameState = {
        queue: ["user-1", "user-2", "user-3"],
        cursor: 0,
        track: mockTrack,
        participants: mockParticipants,
        turn: {
          phase: TURN_PHASE.READY,
          assumptions: []
        }
      };
      
      getScopeContextSpy.mockReturnValue({ user });
      getGameContextSpy.mockReturnValue({ state: gameState });
      
      expect(() => render(CurrentTrack)).not.toThrow();
    });
  });
});
