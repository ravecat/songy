import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { Channel } from "phoenix";
import * as GameContext from "~components/GameContext.svelte";
import GameButton from "~components/GameButton.svelte";

vi.mock("phoenix");

describe("GameButton component", () => {
  let mockChannelContext;
  let getGameContextSpy;
  let mockChannel;

  beforeEach(() => {
    mockChannel = new Channel("room:123", {}, null);
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
      },
      channel: mockChannel,
    };

    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("displays start button when there are 2 or more players", () => {
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(GameButton);

    expect(screen.getByRole("button", { name: "Start" })).toBeInTheDocument();
    expect(
      screen.queryByText("Waiting for another player...")
    ).not.toBeInTheDocument();
  });

  test("displays start button when there are more than 2 players", () => {
    mockChannelContext.state.participants = [
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
      {
        uuid: "user-3",
        name: "Charlie",
        avatar_url: "https://example.com/charlie.jpg",
      },
    ];

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(GameButton);

    expect(screen.getByRole("button", { name: "Start" })).toBeInTheDocument();
    expect(
      screen.queryByText("Waiting for another player...")
    ).not.toBeInTheDocument();
  });

  test("displays waiting message when there is only 1 player", () => {
    mockChannelContext.state.participants = [
      {
        uuid: "user-1",
        name: "Alice",
        avatar_url: "https://example.com/alice.jpg",
      },
    ];

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(GameButton);

    expect(
      screen.getByText("Waiting for another player...")
    ).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("displays waiting message when there are no players", () => {
    mockChannelContext.state.participants = [];

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(GameButton);

    expect(
      screen.getByText("Waiting for another player...")
    ).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("sends START_GAME event when Start button is clicked", async () => {
    const pushSpy = vi.spyOn(mockChannel, "push").mockReturnValue({
      receive: vi.fn().mockReturnValue({ receive: vi.fn() }),
    });

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(GameButton);

    const startButton = screen.getByRole("button", { name: "Start" });
    await fireEvent.click(startButton);

    expect(pushSpy).toHaveBeenCalledWith("start_game", {});
  });

  test("disables start button while loading", async () => {
    const pushSpy = vi.spyOn(mockChannel, "push").mockReturnValue({
      receive: vi.fn().mockReturnValue({ receive: vi.fn() }),
    });

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(GameButton);

    const startButton = screen.getByRole("button", { name: "Start" });
    expect(startButton).not.toBeDisabled();

    await fireEvent.click(startButton);

    expect(startButton).toBeDisabled();
  });

  test("shows loading spinner while loading", async () => {
    let resolveFn;
    const pushPromise = new Promise((resolve) => {
      resolveFn = resolve;
    });

    vi.spyOn(mockChannel, "push").mockReturnValue({
      receive: vi.fn((status, callback) => {
        if (status === "ok") {
          pushPromise.then(callback);
        }
        return { receive: vi.fn() };
      }),
    });

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(GameButton);

    const startButton = screen.getByRole("button", { name: "Start" });
    await fireEvent.click(startButton);

    // The button text should be updated to show loading state
    expect(screen.getByText("Starting...")).toBeInTheDocument();
  });

  test("handles null state gracefully", () => {
    mockChannelContext.state = null;

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(GameButton);

    expect(
      screen.getByText("Waiting for another player...")
    ).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  test("handles undefined participants gracefully", () => {
    mockChannelContext.state.participants = undefined;

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(GameButton);

    expect(
      screen.getByText("Waiting for another player...")
    ).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });
});
