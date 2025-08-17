import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi } from "vitest";
import { Channel } from "phoenix";
import { TURN_PHASE } from "~shared/types/turn";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";

import TurnWaiting from "~components/TurnWaiting.svelte";

vi.mock("phoenix");

describe("TurnWaiting", () => {
  let mockChannelContext;

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
  });

  test("displays current player's name and avatar", () => {
    render(TurnWaiting, {
      context: new Map([[GAME_CONTEXT_KEY, mockChannelContext]]),
    });

    expect(screen.getByText("Alice turn")).toBeInTheDocument();
    expect(screen.getByAltText("Alice")).toBeInTheDocument();
    expect(screen.getByAltText("Alice")).toHaveAttribute(
      "src",
      "https://example.com/alice.jpg"
    );
  });

  test("displays ready button", () => {
    render(TurnWaiting, {
      context: new Map([[GAME_CONTEXT_KEY, mockChannelContext]]),
    });

    expect(screen.getByText("Ready?")).toBeInTheDocument();
    expect(screen.getByRole("button")).toBeInTheDocument();
  });

  test("displays second player when cursor is 1", () => {
    mockChannelContext.state.turn.cursor = 1;

    render(TurnWaiting, {
      context: new Map([[GAME_CONTEXT_KEY, mockChannelContext]]),
    });

    expect(screen.getByText("Bob turn")).toBeInTheDocument();
    expect(screen.getByAltText("Bob")).toBeInTheDocument();
  });

  test("throws error when gameContext is missing", () => {
    expect(() => {
      render(TurnWaiting, {
        context: new Map(),
      });
    }).toThrow("getGameContext() must be called within a game context");
  });

  test("sends next_phase event when Ready button is clicked", async () => {
    render(TurnWaiting, {
      context: new Map([[GAME_CONTEXT_KEY, mockChannelContext]]),
    });

    const readyButton = screen.getByText("Ready?");
    await fireEvent.click(readyButton);

    expect(mockChannelContext.channel.push).toHaveBeenCalledWith(
      "next_phase",
      {}
    );
  });
});
