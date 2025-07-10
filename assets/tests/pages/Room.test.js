import { render, screen, act } from "@testing-library/svelte";
import { afterEach, expect, test, vi } from "vitest";
import Room from "@pages/Room.svelte";
import socket from "@/socket";

vi.mock("@/socket", async () => {
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

    expect(socket.channel.mock.results[0].value.on).toHaveBeenCalledWith(
      "state_updated",
      expect.any(Function)
    );
  });

  test("displays loader when state is null", () => {
    render(Room, { roomId: "test-room" });

    expect(screen.getByText("Connecting to game...")).toBeInTheDocument();
    expect(screen.getByText("Connecting to game...")).toBeVisible();
  });

  test("displays start button on waiting state", async () => {
    render(Room, { roomId: "test-room" });

    const channel = socket.channel.mock.results[0].value;

    const [, cb] = channel.on.mock.calls.find(
      ([eventName]) => eventName === "state_updated"
    );

    await cb({
      participants: [
        { name: "User1", avatar_url: "avatar1.jpg" },
        { name: "User2", avatar_url: "avatar2.jpg" },
      ],
      max_participants: 4,
      status: "waiting",
    });

    expect(screen.getByText("Start")).toBeInTheDocument();
    expect(screen.getByText("Start")).toBeVisible();
  });
});
