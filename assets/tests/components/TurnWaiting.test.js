import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { Channel } from "phoenix";
import { TURN_PHASE } from "~shared/types/turn";
import * as GameContext from "~components/GameChannel.svelte";
import * as Scope from "~components/Scope.svelte";

import TurnWaiting from "~components/TurnWaiting.svelte";

vi.mock("phoenix");

describe("Turn waiting view", () => {
  let mockChannelContext;
  let getScopeContextSpy;
  let getGameContextSpy;

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
        queue: ["user-1", "user-2"],
        cursor: 0,
        turn: {
          phase: TURN_PHASE.WAITING,
        },
      },
      channel: new Channel("room:123", {}, null),
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

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnWaiting);

    expect(screen.getByText("It's your turn")).toBeInTheDocument();
    expect(screen.getByAltText("Alice")).toBeInTheDocument();
    expect(screen.getByAltText("Alice")).toHaveAttribute(
      "src",
      "https://example.com/alice.jpg"
    );
  });

  test("displays ready button when current user is active player", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnWaiting);

    expect(screen.getByText("Ready?")).toBeInTheDocument();
    expect(screen.getByRole("button")).toBeInTheDocument();
  });

  test("hides ready button when current user is not active player", () => {
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
    expect(screen.queryByText("Ready?")).not.toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("displays second player when cursor is 1 and shows ready button for them", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };

    mockChannelContext.state.cursor = 1;

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnWaiting);

    expect(screen.getByText("It's your turn")).toBeInTheDocument();
    expect(screen.getByAltText("Bob")).toBeInTheDocument();
    expect(screen.getByText("Ready?")).toBeInTheDocument();
  });

  test("shows active player info but hides button when different user is viewing", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    mockChannelContext.state.cursor = 1;

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnWaiting);

    expect(screen.getByText("Bob turn")).toBeInTheDocument();
    expect(screen.getByAltText("Bob")).toBeInTheDocument();
    expect(screen.queryByText("Ready?")).not.toBeInTheDocument();
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

  test("sends next_phase event when Ready button is clicked by active player", async () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    const pushSpy = vi.spyOn(mockChannelContext.channel, "push");

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnWaiting);

    const readyButton = screen.getByRole("button");
    await fireEvent.click(readyButton);

    expect(pushSpy).toHaveBeenCalledWith("next_phase", {});
  });
});
