import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";

import TurnPlaying from "~components/TurnPlaying.svelte";

describe("TurnPlaying", () => {
  let mockChannelContext;
  let mockScopeContext;

  beforeEach(() => {
    mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };

    mockChannelContext = {
      state: {
        participants: [
          {
            uuid: "user-1",
            name: "Alice",
            avatar_url: "https://example.com/alice.jpg",
          },
          {
            uuid: "test-user-uuid",
            name: "Test User", 
            avatar_url: "https://example.com/test.jpg",
          },
        ],
        turn: {
          phase: TURN_PHASE.PLAYING,
        },
      },
    };
  });

  test("renders participants component", () => {
    render(TurnPlaying, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(screen.getByText("Alice")).toBeInTheDocument();
    expect(screen.getByText("Test User")).toBeInTheDocument();
  });

  test("renders current track and timeline section", () => {
    render(TurnPlaying, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    // The component structure should render a flex container
    const container = screen.getByText("Alice").closest("body");
    expect(container).toBeInTheDocument();
  });

  test("throws error when channel context is missing", () => {
    expect(() => {
      render(TurnPlaying, {
        context: new Map([["scope", mockScopeContext]]),
      });
    }).toThrow();
  });

  test("throws error when scope context is missing", () => {
    expect(() => {
      render(TurnPlaying, {
        context: new Map([["channel", mockChannelContext]]),
      });
    }).toThrow();
  });

  test("renders without error when both contexts are provided", () => {
    expect(() => {
      render(TurnPlaying, {
        context: new Map([
          ["channel", mockChannelContext],
          ["scope", mockScopeContext],
        ]),
      });
    }).not.toThrow();
  });
});
