import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import * as GameContext from "~components/GameChannel.svelte";
import * as Scope from "~components/Scope.svelte";

import TurnWaiting from "~components/TurnWaiting.svelte";

describe("Turn waiting view", () => {
  let mockChannelContext;
  let getScopeContextSpy;
  let getGameContextSpy;

  beforeEach(() => {
    mockChannelContext = {
      game: {
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
        queue: ["user-1", "user-2"],
        cursor: 0,
        turn: {
          phase: TURN_PHASE.WAITING,
        },
      },
      permissions: {
        can_start_turn: false,
        can_control_playback: false,
        can_advance_turn: false,
        can_start_game: false,
        can_ready: false,
        can_restart_game: false,
        can_see_assumptions: false,
        can_make_assumptions: false,
      },
    };

    getScopeContextSpy = vi.spyOn(Scope, "getScopeContext");
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("displays personalized message when current user is active player", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    const mockContextActive = {
      ...mockChannelContext,
      permissions: {
        ...mockChannelContext.permissions,
        can_start_turn: true,
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockContextActive);

    render(TurnWaiting);

    expect(screen.getByText("It's your turn")).toBeInTheDocument();
    expect(screen.getByAltText("Alice")).toBeInTheDocument();
    expect(screen.getByAltText("Alice")).toHaveAttribute(
      "src",
      "https://example.com/alice.jpg"
    );
  });

  test("does not render controls when current user is not active player", () => {
    const nonActiveUserContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };

    getScopeContextSpy.mockReturnValue(nonActiveUserContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnWaiting);

    expect(screen.getByText("Alice turn")).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("displays second player when cursor is 1", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };

    mockChannelContext.game.cursor = 1;

    const mockContextActive = {
      ...mockChannelContext,
      permissions: {
        ...mockChannelContext.permissions,
        can_start_turn: true,
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockContextActive);

    render(TurnWaiting);

    expect(screen.getByText("It's your turn")).toBeInTheDocument();
    expect(screen.getByAltText("Bob")).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("shows active player info but hides button when different user is viewing", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    mockChannelContext.game.cursor = 1;

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnWaiting);

    expect(screen.getByText("Bob turn")).toBeInTheDocument();
    expect(screen.getByAltText("Bob")).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("throws error when gameContext is missing", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockImplementation(() => {
      throw new Error("getGameContext() must be called within a game context");
    });

    expect(() => {
      render(TurnWaiting);
    }).toThrow("getGameContext() must be called within a game context");
  });

  test("throws error when scopeContext is missing", () => {
    getScopeContextSpy.mockImplementation(() => {
      throw new Error("missing_context");
    });
    getGameContextSpy.mockReturnValue(mockChannelContext);

    expect(() => {
      render(TurnWaiting);
    }).toThrow("missing_context");
  });

});
