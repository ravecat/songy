import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi } from "vitest";
import { Channel } from "phoenix";
import { TURN_PHASE } from "~shared/types/turn";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import { SCOPE_CONTEXT_KEY } from "~components/Scope.svelte";

import TurnWaiting from "~components/TurnWaiting.svelte";

vi.mock("phoenix");

describe("Turn waiting view", () => {
  let mockChannelContext;
  let mockScopeContext;

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
          queue: ["user-1", "user-2"],
          cursor: 0,
          phase: TURN_PHASE.WAITING,
        },
      },
      channel: new Channel("room:123", {}, null),
    };

    mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };
  });

  test("displays personalized message when current user is active player", () => {
    render(TurnWaiting, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.getByText("It's your turn")).toBeInTheDocument();
    expect(screen.getByAltText("Alice")).toBeInTheDocument();
    expect(screen.getByAltText("Alice")).toHaveAttribute(
      "src",
      "https://example.com/alice.jpg"
    );
  });

  test("displays ready button when current user is active player", () => {
    render(TurnWaiting, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

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

    render(TurnWaiting, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, nonActiveUserContext],
      ]),
    });

    expect(screen.getByText("Alice turn")).toBeInTheDocument();
    expect(screen.queryByText("Ready?")).not.toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("displays second player when cursor is 1 and shows ready button for them", () => {
    mockChannelContext.state.turn.cursor = 1;
    mockScopeContext.user = {
      uuid: "user-2",
      name: "Bob",
    };

    render(TurnWaiting, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.getByText("It's your turn")).toBeInTheDocument();
    expect(screen.getByAltText("Bob")).toBeInTheDocument();
    expect(screen.getByText("Ready?")).toBeInTheDocument();
  });

  test("shows active player info but hides button when different user is viewing", () => {
    mockChannelContext.state.turn.cursor = 1;
    mockScopeContext.user = {
      uuid: "user-1",
      name: "Alice",
    };

    render(TurnWaiting, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.getByText("Bob turn")).toBeInTheDocument();
    expect(screen.getByAltText("Bob")).toBeInTheDocument();
    expect(screen.queryByText("Ready?")).not.toBeInTheDocument();
  });

  test("throws error when gameContext is missing", () => {
    expect(() => {
      render(TurnWaiting, {
        context: new Map([[SCOPE_CONTEXT_KEY, mockScopeContext]]),
      });
    }).toThrow("getGameContext() must be called within a game context");
  });

  test("throws error when scopeContext is missing", () => {
    expect(() => {
      render(TurnWaiting, {
        context: new Map([[GAME_CONTEXT_KEY, mockChannelContext]]),
      });
    }).toThrow("getScopeContext() must be called within a scope context");
  });

  test("sends next_phase event when Ready button is clicked by active player", async () => {
    const pushSpy = vi.spyOn(mockChannelContext.channel, "push");

    render(TurnWaiting, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    const readyButton = screen.getByRole("button");
    await fireEvent.click(readyButton);

    expect(pushSpy).toHaveBeenCalledWith("next_phase", {});
  });
});
