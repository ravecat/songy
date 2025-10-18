import { render, screen } from "@testing-library/svelte";
import { afterEach, expect, test, vi } from "vitest";
import Room from "~pages/Room.svelte";
import socket from "~/socket";

vi.mock("~/socket", async () => {
  const { Socket } = await vi.importMock("phoenix");

  return {
    default: new Socket("/socket", {}),
  };
});

describe("Room", () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  test("joins to channel with room id", () => {
    render(Room, { roomId: "test-room" });

    expect(socket.channel).toHaveBeenCalledWith("room:test-room", {});
  });

  test("listens state_updated event", () => {
    render(Room, { roomId: "test-room" });

    const channel = socket.channel.mock.results[0].value;

    expect(channel.on).toHaveBeenCalledWith(
      "state_updated",
      expect.any(Function)
    );
  });
});
