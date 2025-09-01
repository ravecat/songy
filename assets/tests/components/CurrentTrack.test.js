import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import { SCOPE_CONTEXT_KEY } from "~components/Scope.svelte";

import CurrentTrack from "~components/CurrentTrack.svelte";

describe("Current track component", () => {
  let mockTrack;
  let mockParticipants;

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
  });

  describe("in READY phase", () => {
    describe("for active player", () => {
      test("shows current track when player has not made assumption", () => {
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
        const user = { uuid: "user-1", name: "Alice" };
        
        render(CurrentTrack, {
          context: new Map([
            [GAME_CONTEXT_KEY, { state: gameState }],
            [SCOPE_CONTEXT_KEY, { user }]
          ])
        });
        
        expect(screen.getByRole("list")).toBeInTheDocument();
      });

      test("hides current track when player has made assumption", () => {
        const gameState = {
          turn: {
            phase: TURN_PHASE.READY,
            queue: ["user-1", "user-2", "user-3"],
            cursor: 0,
            track: mockTrack,
            assumptions: [{ position: 0, user_id: "user-1" }]
          },
          participants: mockParticipants
        };
        const user = { uuid: "user-1", name: "Alice" };
        
        render(CurrentTrack, {
          context: new Map([
            [GAME_CONTEXT_KEY, { state: gameState }],
            [SCOPE_CONTEXT_KEY, { user }]
          ])
        });
        
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
      });
    });

    describe("for non-active players", () => {
      test("hides current track regardless of assumption status", () => {
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
        const user = { uuid: "user-2", name: "Bob" };
        
        render(CurrentTrack, {
          context: new Map([
            [GAME_CONTEXT_KEY, { state: gameState }],
            [SCOPE_CONTEXT_KEY, { user }]
          ])
        });
        
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
      });
    });
  });

  describe("in CHALLENGING phase", () => {
    describe("for active player", () => {
      test("hides current track regardless of assumption status", () => {
        const gameState = {
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            queue: ["user-1", "user-2", "user-3"],
            cursor: 0,
            track: mockTrack,
            assumptions: []
          },
          participants: mockParticipants
        };
        const user = { uuid: "user-1", name: "Alice" };
        
        render(CurrentTrack, {
          context: new Map([
            [GAME_CONTEXT_KEY, { state: gameState }],
            [SCOPE_CONTEXT_KEY, { user }]
          ])
        });
        
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
      });
    });

    describe("for challenger players", () => {
      test("shows current track when player has not made assumption", () => {
        const gameState = {
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            queue: ["user-1", "user-2", "user-3"],
            cursor: 0,
            track: mockTrack,
            assumptions: []
          },
          participants: mockParticipants
        };
        const user = { uuid: "user-2", name: "Bob" };
        
        render(CurrentTrack, {
          context: new Map([
            [GAME_CONTEXT_KEY, { state: gameState }],
            [SCOPE_CONTEXT_KEY, { user }]
          ])
        });
        
        expect(screen.getByRole("list")).toBeInTheDocument();
      });

      test("hides current track when player has made assumption", () => {
        const gameState = {
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            queue: ["user-1", "user-2", "user-3"],
            cursor: 0,
            track: mockTrack,
            assumptions: [{ position: 0, user_id: "user-2" }]
          },
          participants: mockParticipants
        };
        const user = { uuid: "user-2", name: "Bob" };
        
        render(CurrentTrack, {
          context: new Map([
            [GAME_CONTEXT_KEY, { state: gameState }],
            [SCOPE_CONTEXT_KEY, { user }]
          ])
        });
        
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
      });

      test("displays track card with question mark to hide track details", () => {
        const gameState = {
          turn: {
            phase: TURN_PHASE.CHALLENGING,
            queue: ["user-1", "user-2", "user-3"],
            cursor: 0,
            track: mockTrack,
            assumptions: []
          },
          participants: mockParticipants
        };
        const user = { uuid: "user-2", name: "Bob" };
        
        render(CurrentTrack, {
          context: new Map([
            [GAME_CONTEXT_KEY, { state: gameState }],
            [SCOPE_CONTEXT_KEY, { user }]
          ])
        });
        
        expect(screen.getByText("?")).toBeInTheDocument();
        expect(screen.queryByText("Test Song")).not.toBeInTheDocument();
        expect(screen.queryByText("Test Artist")).not.toBeInTheDocument();
      });
    });
  });

  describe("in other game phases", () => {
    [TURN_PHASE.WAITING, TURN_PHASE.STEADY, TURN_PHASE.RESULTS].forEach(phase => {
      test(`hides current track in ${phase} phase`, () => {
        const gameState = {
          turn: {
            phase: phase,
            queue: ["user-1", "user-2", "user-3"],
            cursor: 0,
            track: mockTrack,
            assumptions: []
          },
          participants: mockParticipants
        };
        const user = { uuid: "user-1", name: "Alice" };
        
        render(CurrentTrack, {
          context: new Map([
            [GAME_CONTEXT_KEY, { state: gameState }],
            [SCOPE_CONTEXT_KEY, { user }]
          ])
        });
        
        expect(screen.queryByRole("list")).not.toBeInTheDocument();
      });
    });
  });

  describe("with edge cases", () => {
    test("handles missing turn state gracefully", () => {
      const gameState = { participants: mockParticipants };
      const user = { uuid: "user-1", name: "Alice" };
      
      expect(() => render(CurrentTrack, {
        context: new Map([
          [GAME_CONTEXT_KEY, { state: gameState }],
          [SCOPE_CONTEXT_KEY, { user }]
        ])
      })).not.toThrow();
      
      expect(screen.queryByRole("list")).not.toBeInTheDocument();
    });

    test("handles empty player queue gracefully", () => {
      const gameState = {
        turn: {
          phase: TURN_PHASE.READY,
          queue: [],
          cursor: 0,
          track: mockTrack,
          assumptions: []
        },
        participants: mockParticipants
      };
      const user = { uuid: "user-1", name: "Alice" };
      
      render(CurrentTrack, {
        context: new Map([
          [GAME_CONTEXT_KEY, { state: gameState }],
          [SCOPE_CONTEXT_KEY, { user }]
        ])
      });
      
      expect(screen.queryByRole("list")).not.toBeInTheDocument();
    });

    test("handles invalid cursor position gracefully", () => {
      const gameState = {
        turn: {
          phase: TURN_PHASE.READY,
          queue: ["user-1", "user-2"],
          cursor: 5, // Invalid cursor
          track: mockTrack,
          assumptions: []
        },
        participants: mockParticipants
      };
      const user = { uuid: "user-1", name: "Alice" };
      
      render(CurrentTrack, {
        context: new Map([
          [GAME_CONTEXT_KEY, { state: gameState }],
          [SCOPE_CONTEXT_KEY, { user }]
        ])
      });
      
      expect(screen.queryByRole("list")).not.toBeInTheDocument();
    });

    test("handles missing track data gracefully", () => {
      const gameState = {
        turn: {
          phase: TURN_PHASE.READY,
          queue: ["user-1", "user-2"],
          cursor: 0,
          track: null,
          assumptions: []
        },
        participants: mockParticipants
      };
      const user = { uuid: "user-1", name: "Alice" };
      
      render(CurrentTrack, {
        context: new Map([
          [GAME_CONTEXT_KEY, { state: gameState }],
          [SCOPE_CONTEXT_KEY, { user }]
        ])
      });
      
      expect(screen.queryByRole("list")).not.toBeInTheDocument();
    });
  });

  describe("with required contexts", () => {
    test("throws error when game context is missing", () => {
      const user = { uuid: "user-1", name: "Alice" };
      
      expect(() => {
        render(CurrentTrack, {
          context: new Map([[SCOPE_CONTEXT_KEY, { user }]]),
        });
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
      
      expect(() => {
        render(CurrentTrack, {
          context: new Map([[GAME_CONTEXT_KEY, { state: gameState }]]),
        });
      }).toThrow();
    });

    test("renders without error when both contexts are provided", () => {
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
      const user = { uuid: "user-1", name: "Alice" };
      
      expect(() => render(CurrentTrack, {
        context: new Map([
          [GAME_CONTEXT_KEY, { state: gameState }],
          [SCOPE_CONTEXT_KEY, { user }]
        ])
      })).not.toThrow();
    });
  });
});
