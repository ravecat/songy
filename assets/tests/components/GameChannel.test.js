import { render } from "@testing-library/svelte";
import { afterEach, expect, test, vi } from "vitest";
import GameChannel from "~components/GameChannel.svelte";
import socket from "~/socket";

vi.mock("~/socket", async () => {
  const { Socket } = await vi.importMock("phoenix");

  return {
    default: new Socket("/socket", {}),
  };
});

describe("GameChannel", () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  test("joins to channel with provided topic", () => {
    render(GameChannel, { socket, topic: "room:test-room" });

    expect(socket.channel).toHaveBeenCalledWith("room:test-room", {});
  });

  test("listens state event", () => {
    render(GameChannel, { socket, topic: "room:test-room" });

    const channel = socket.channel.mock.results[0].value;

    expect(channel.on).toHaveBeenCalledWith(
      "state",
      expect.any(Function)
    );
  });
});
