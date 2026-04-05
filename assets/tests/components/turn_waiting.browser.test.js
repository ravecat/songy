import { writable } from "svelte/store";
import { render } from "vitest-browser-svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";

vi.mock("~/contexts/game");

import TurnWaiting from "~components/turn_waiting.svelte";
import { getGameContext } from "~/contexts/game";

describe("Turn waiting view", () => {
  let mockChannelContext;

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
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("displays personalized message when current user is active player", async () => {
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
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...mockContextActive,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(TurnWaiting);

    await expect.element(screen.getByText("It's your turn")).toBeVisible();
    await expect.element(screen.getByAltText("Alice")).toHaveAttribute(
      "src",
      "https://example.com/alice.jpg",
    );
  });

  test("does not render controls when current user is not active player", async () => {
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
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...mockContextNotActive,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(TurnWaiting);

    await expect.element(screen.getByText("Alice turn")).toBeVisible();
    await expect.element(screen.getByRole("button")).not.toBeInTheDocument();
  });

  test("displays second player when cursor is 1", async () => {
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
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...mockContextActive,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(TurnWaiting);

    await expect.element(screen.getByText("It's your turn")).toBeVisible();
    await expect.element(screen.getByAltText("Bob")).toHaveAttribute(
      "src",
      "https://example.com/bob.jpg",
    );
    await expect.element(screen.getByRole("button")).not.toBeInTheDocument();
  });

  test("shows active player info but hides button when different user is viewing", async () => {
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
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...mockContextNonActive,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(TurnWaiting);

    await expect.element(screen.getByText("Bob turn")).toBeVisible();
    await expect.element(screen.getByAltText("Bob")).toHaveAttribute(
      "src",
      "https://example.com/bob.jpg",
    );
    await expect.element(screen.getByRole("button")).not.toBeInTheDocument();
  });

  test("throws error when gameContext is missing", () => {
    vi.mocked(getGameContext).mockImplementation(() => {
      throw new Error("missing game context");
    });

    expect(() => {
      render(TurnWaiting);
    }).toThrow();
  });
});
