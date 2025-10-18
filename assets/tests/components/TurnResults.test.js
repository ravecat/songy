import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { Channel } from "phoenix";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import * as Scope from "~components/Scope.svelte";
import { GAME_STATUS } from "~shared/types/game";
import { PUSH_EVENT } from "~shared/types/channel";

import TurnResults from "~components/TurnResults.svelte";

vi.mock("phoenix");

describe("Turn results view", () => {
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
          {
            uuid: "user-2",
            name: "Bob",
            avatar_url: "https://example.com/bob.jpg",
          },
        ],
        turn: {
          timeline: [],
          queue: ["user-1", "user-2"],
          cursor: 0,
        },
        status: GAME_STATUS.IN_PROGRESS,
      },
      channel: new Channel("room:123", {}, null),
    };

    getScopeContextSpy = vi.spyOn(Scope, 'getScopeContext');
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders participants", () => {
    const mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);
    
    render(TurnResults, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext]
      ]),
    });

    expect(screen.getByText("Alice")).toBeInTheDocument();
    expect(screen.getByText("Bob")).toBeInTheDocument();
  });

  test("renders active timeline", () => {
    const mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);
    
    render(TurnResults, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext]
      ]),
    });

    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  describe("when game is finished", () => {
    beforeEach(() => {
      mockChannelContext.state.status = GAME_STATUS.FINISHED;
    });

    test("displays play again button", () => {
      const mockScopeContext = {
        user: {
          uuid: "test-user-uuid",
          name: "Test User",
        },
      };
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);
      
      render(TurnResults, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext]
        ]),
      });

      expect(screen.getByText("Play again")).toBeInTheDocument();
      expect(
        screen.getByRole("button", { name: "Play again" })
      ).toBeInTheDocument();
      expect(
        screen.getByText("Play again").closest("form")
      ).toBeInTheDocument();
      expect(screen.getByText("Play again")).toHaveAttribute("type", "submit");
    });

    test("does not display next turn button", () => {
      const mockScopeContext = {
        user: {
          uuid: "test-user-uuid",
          name: "Test User",
        },
      };
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);
      
      render(TurnResults, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext]
        ]),
      });

      expect(screen.queryByText("Next Turn")).not.toBeInTheDocument();
    });
  });

  describe("when game is not finished", () => {
    test("displays next turn button", () => {
      const mockScopeContext = {
        user: {
          uuid: "test-user-uuid",
          name: "Test User",
        },
      };
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);
      
      render(TurnResults, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext]
        ]),
      });

      expect(screen.getByText("Next Turn")).toBeInTheDocument();
      expect(
        screen.getByRole("button", { name: "Next Turn" })
      ).toBeInTheDocument();
    });

    test("does not display play again button", () => {
      const mockScopeContext = {
        user: {
          uuid: "test-user-uuid",
          name: "Test User",
        },
      };
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);
      
      render(TurnResults, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext]
        ]),
      });

      expect(screen.queryByText("Play again")).not.toBeInTheDocument();
    });

    test("sends next phase event when next turn button is clicked", async () => {
      const mockScopeContext = {
        user: {
          uuid: "test-user-uuid",
          name: "Test User",
        },
      };
      
      getScopeContextSpy.mockReturnValue(mockScopeContext);
      
      render(TurnResults, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext]
        ]),
      });

      await fireEvent.click(screen.getByText("Next Turn"));

      expect(mockChannelContext.channel.push).toHaveBeenCalledWith(
        PUSH_EVENT.NEXT_PHASE,
        {}
      );
    });
  });
});
