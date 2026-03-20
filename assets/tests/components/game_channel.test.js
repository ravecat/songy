import { render, screen } from "@testing-library/svelte";
import { tick } from "svelte";
import { afterEach, describe, expect, test, vi } from "vitest";
import GameChannel from "~components/game_channel.svelte";
import { BROADCAST_EVENT } from "~shared/types/channel";
import socket from "~/socket";

vi.mock("~/socket", async () => {
  const { Socket } = await import("phoenix");

  return {
    default: new Socket("/socket", {}),
  };
});

describe("GameChannel", () => {
  afterEach(() => {
    vi.clearAllMocks();
    vi.useRealTimers();
  });

  test("joins to channel with provided topic", () => {
    const { unmount } = render(GameChannel, {
      socket,
      topic: "room:test-room",
    });

    expect(socket.channel).toHaveBeenCalledWith("room:test-room", {});

    unmount();
  });

  test("listens state event", () => {
    const { unmount } = render(GameChannel, {
      socket,
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results[0].value;

    expect(channel.on).toHaveBeenCalledWith(
      BROADCAST_EVENT.STATE,
      expect.any(Function),
    );

    unmount();
  });

  test("renders loader while waiting for state", async () => {
    const { unmount } = render(GameChannel, {
      socket,
      topic: "room:test-room",
    });

    await tick();

    expect(screen.getByRole("status", { name: "loading" })).toBeInTheDocument();
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();

    unmount();
  });

  test("hides loader after receiving state event", async () => {
    const { unmount } = render(GameChannel, {
      socket,
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;
    const stateCallback = channel.on.mock.calls.find(
      ([event]) => event === BROADCAST_EVENT.STATE,
    )?.[1];

    expect(stateCallback).toEqual(expect.any(Function));

    stateCallback({
      game: { id: "game-1" },
      permissions: { can_start_game: true },
    });

    await tick();

    expect(
      screen.queryByRole("status", { name: "loading" }),
    ).not.toBeInTheDocument();
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();

    unmount();
  });

  test("renders error screen when join fails with reason", async () => {
    const { unmount } = render(GameChannel, {
      socket,
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;
    const push = channel.join.mock.results[0].value;
    const errorHandler = push.receive.mock.calls.find(
      ([status]) => status === "error",
    )?.[1];

    expect(errorHandler).toEqual(expect.any(Function));

    errorHandler({ reason: "not_allowed" });
    await tick();

    expect(screen.getByRole("alert")).toBeInTheDocument();
    expect(screen.getByText("Room unavailable")).toBeInTheDocument();
    expect(screen.getByText("Reason: not_allowed")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Back home" })).toHaveAttribute(
      "href",
      "/",
    );

    unmount();
  });

  test("renders error screen when join times out", async () => {
    const { unmount } = render(GameChannel, {
      socket,
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;
    const push = channel.join.mock.results[0].value;
    const timeoutHandler = push.receive.mock.calls.find(
      ([status]) => status === "timeout",
    )?.[1];

    expect(timeoutHandler).toEqual(expect.any(Function));

    timeoutHandler();

    await tick();

    expect(screen.getByRole("alert")).toBeInTheDocument();
    expect(screen.getByText("Room unavailable")).toBeInTheDocument();
    expect(screen.getByText("Failed to load game state.")).toBeInTheDocument();

    unmount();
  });

  test("renders error screen when channel closes unexpectedly", async () => {
    const { unmount } = render(GameChannel, {
      socket,
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;
    const onClose = channel.onClose.mock.calls[0]?.[0];

    expect(onClose).toEqual(expect.any(Function));

    onClose();
    await tick();

    expect(screen.getByRole("alert")).toBeInTheDocument();
    expect(screen.getByText("Room unavailable")).toBeInTheDocument();
    expect(screen.getByText("Failed to load game state.")).toBeInTheDocument();

    unmount();
  });

  test("renders error screen when state takes too long", async () => {
    const { unmount } = render(GameChannel, {
      socket,
      topic: "room:test-room",
      timeoutMs: 10,
    });

    await tick();
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();

    await new Promise((r) => setTimeout(r, 50));
    await tick();

    expect(screen.getByRole("alert")).toBeInTheDocument();
    expect(screen.getByText("Room unavailable")).toBeInTheDocument();
    expect(screen.getByText("Failed to load game state.")).toBeInTheDocument();

    unmount();
  });

  test("does not render timeout error after state is received", async () => {
    const { unmount } = render(GameChannel, {
      socket,
      topic: "room:test-room",
      timeoutMs: 10,
    });

    const channel = socket.channel.mock.results.at(-1).value;
    const stateCallback = channel.on.mock.calls.find(
      ([event]) => event === BROADCAST_EVENT.STATE,
    )?.[1];

    stateCallback({
      game: { id: "game-1" },
      permissions: { can_start_game: true },
    });
    await tick();

    expect(
      screen.queryByRole("status", { name: "loading" }),
    ).not.toBeInTheDocument();
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();

    await new Promise((r) => setTimeout(r, 50));
    await tick();

    expect(
      screen.queryByRole("status", { name: "loading" }),
    ).not.toBeInTheDocument();
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();

    unmount();
  });

  test("leaves channel on unmount", () => {
    const { unmount } = render(GameChannel, {
      socket,
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;
    unmount();

    expect(channel.leave).toHaveBeenCalledTimes(1);
  });
});
