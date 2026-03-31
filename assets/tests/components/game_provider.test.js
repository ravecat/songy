import { render, screen } from "@testing-library/svelte";
import { tick } from "svelte";
import { afterEach, describe, expect, test, vi } from "vitest";
import GameProvider from "~components/game_provider.svelte";
import socket from "~/transport/socket";

vi.mock("~/transport/socket", async () => {
  const { Socket } = await import("phoenix");

  return {
    default: new Socket("/socket", {}),
  };
});

function getReceiveHandler(push, status) {
  return push.receive.mock.calls
    .filter(([currentStatus]) => currentStatus === status)
    .at(-1)?.[1];
}

function buildStatePayload() {
  return {
    game: {
      id: "game-1",
      owner_id: "owner-1",
      max_participants: 8,
      max_score: 10,
      status: "waiting",
      participants: {},
      scores: {},
      player: null,
      timelines: {},
      created_at: "2026-01-01T00:00:00Z",
      queue: [],
      cursor: 0,
      track: null,
      turn: null,
    },
    permissions: {
      can_control_playback: false,
      can_advance_turn: false,
      can_start_game: true,
      can_start_turn: false,
      can_restart_game: false,
      can_see_assumptions: false,
      can_make_assumptions: false,
    },
  };
}

describe("GameProvider", () => {
  afterEach(() => {
    vi.clearAllMocks();
    vi.useRealTimers();
  });

  test("joins to channel with provided topic", () => {
    const { unmount } = render(GameProvider, {
      topic: "room:test-room",
    });

    expect(socket.channel).toHaveBeenCalledWith("room:test-room", {});

    unmount();
  });

  test("listens state event", () => {
    const { unmount } = render(GameProvider, {
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results[0].value;

    expect(channel.on).toHaveBeenCalledWith(
      "state",
      expect.any(Function),
    );

    unmount();
  });

  test("renders loader while waiting for join reply", async () => {
    const { unmount } = render(GameProvider, {
      topic: "room:test-room",
    });

    await tick();

    expect(screen.getByRole("status", { name: "loading" })).toBeInTheDocument();
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();

    unmount();
  });

  test("hides loader after receiving join reply", async () => {
    const { unmount } = render(GameProvider, {
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;
    const push = channel.join.mock.results[0].value;
    const okHandler = getReceiveHandler(push, "ok");

    expect(okHandler).toEqual(expect.any(Function));

    okHandler(buildStatePayload());

    await tick();

    expect(
      screen.queryByRole("status", { name: "loading" }),
    ).not.toBeInTheDocument();
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();

    unmount();
  });

  test("renders error screen when join fails with reason", async () => {
    const { unmount } = render(GameProvider, {
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;
    const push = channel.join.mock.results[0].value;
    const errorHandler = getReceiveHandler(push, "error");

    expect(errorHandler).toEqual(expect.any(Function));

    errorHandler({ reason: "game_not_found" });
    await tick();

    expect(screen.getByRole("alert")).toBeInTheDocument();
    expect(screen.getByText("Room unavailable")).toBeInTheDocument();
    expect(screen.getByText("Reason: game_not_found")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Back home" })).toHaveAttribute(
      "href",
      "/",
    );

    unmount();
  });

  test("renders error screen when join times out", async () => {
    const { unmount } = render(GameProvider, {
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;
    const push = channel.join.mock.results[0].value;
    const timeoutHandler = getReceiveHandler(push, "timeout");

    expect(timeoutHandler).toEqual(expect.any(Function));

    timeoutHandler();

    await tick();

    expect(screen.getByRole("alert")).toBeInTheDocument();
    expect(screen.getByText("Room unavailable")).toBeInTheDocument();
    expect(screen.getByText("Failed to load game state.")).toBeInTheDocument();

    unmount();
  });

  test("renders error screen when channel closes unexpectedly", async () => {
    const { unmount } = render(GameProvider, {
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

  test("ignores close after join succeeded", async () => {
    const { unmount } = render(GameProvider, {
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;
    const push = channel.join.mock.results[0].value;
    const okHandler = getReceiveHandler(push, "ok");
    const onClose = channel.onClose.mock.calls[0]?.[0];

    okHandler(buildStatePayload());
    await tick();

    onClose();
    await tick();

    expect(screen.queryByRole("alert")).not.toBeInTheDocument();
    expect(
      screen.queryByRole("status", { name: "loading" }),
    ).not.toBeInTheDocument();

    unmount();
  });

  test("leaves channel on unmount", () => {
    const { unmount } = render(GameProvider, {
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;
    unmount();

    expect(channel.leave).toHaveBeenCalledTimes(1);
  });
});
