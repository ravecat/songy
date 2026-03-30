import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import * as GameContext from "~/contexts/game";

import TurnWaiting from "~components/turn_waiting.svelte";

describe("Turn waiting view", () => {
  let mockChannelContext;
  let getGameContextSpy;

  beforeEach(() => {
    mockChannelContext = {
      snapshot: {
        game: {
          participants: {
            "user-1": {
              uuid: "user-1",
              name: "Alice",
              avatar_url: "https://example.com/alice.jpg",
            },
            "user-2": {
              uuid: "user-2",
              name: "Bob",
              avatar_url: "https://example.com/bob.jpg",
            },
          },
          queue: ["user-1", "user-2"],
          cursor: 0,
          turn: {
            phase: "waiting",
            assumptions: {},
            winner_id: null,
          },
        },
        permissions: {
          can_start_turn: false,
          can_control_playback: false,
          can_advance_turn: false,
          can_start_game: false,
          can_restart_game: false,
          can_see_assumptions: false,
          can_make_assumptions: false,
        },
      },
    };
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("displays personalized message when current user is active player", () => {
    const mockContextActive = {
      ...mockChannelContext,
      snapshot: {
        ...mockChannelContext.snapshot,
        permissions: {
          ...mockChannelContext.snapshot.permissions,
          can_start_turn: true,
        },
      },
    };
    getGameContextSpy.mockReturnValue(mockContextActive);

    render(TurnWaiting);

    expect(screen.getByText("It's your turn")).toBeInTheDocument();
    expect(screen.getByAltText("Alice")).toBeInTheDocument();
    expect(screen.getByAltText("Alice")).toHaveAttribute(
      "src",
      "https://example.com/alice.jpg",
    );
  });

  test("does not render controls when current user is not active player", () => {
    const mockContextNotActive = {
      ...mockChannelContext,
      snapshot: {
        ...mockChannelContext.snapshot,
        permissions: {
          ...mockChannelContext.snapshot.permissions,
          can_start_turn: false,
        },
      },
    };
    getGameContextSpy.mockReturnValue(mockContextNotActive);

    render(TurnWaiting);

    expect(screen.getByText("Alice turn")).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("displays second player when cursor is 1", () => {
    mockChannelContext.snapshot.game.cursor = 1;

    const mockContextActive = {
      ...mockChannelContext,
      snapshot: {
        ...mockChannelContext.snapshot,
        permissions: {
          ...mockChannelContext.snapshot.permissions,
          can_start_turn: true,
        },
      },
    };
    getGameContextSpy.mockReturnValue(mockContextActive);

    render(TurnWaiting);

    expect(screen.getByText("It's your turn")).toBeInTheDocument();
    expect(screen.getByAltText("Bob")).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("shows active player info but hides button when different user is viewing", () => {
    mockChannelContext.snapshot.game.cursor = 1;

    const mockContextNonActive = {
      ...mockChannelContext,
      snapshot: {
        ...mockChannelContext.snapshot,
        permissions: {
          ...mockChannelContext.snapshot.permissions,
          can_start_turn: false,
        },
      },
    };
    getGameContextSpy.mockReturnValue(mockContextNonActive);

    render(TurnWaiting);

    expect(screen.getByText("Bob turn")).toBeInTheDocument();
    expect(screen.getByAltText("Bob")).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("throws error when gameContext is missing", () => {
    getGameContextSpy.mockImplementation(() => {
      throw new Error("getGameContext() must be called within a game context");
    });

    expect(() => {
      render(TurnWaiting);
    }).toThrow("getGameContext() must be called within a game context");
  });

});
