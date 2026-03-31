import { beforeEach, describe, expect, test, vi } from "vitest";
import socket from "~/transport/socket";
import { createTransport } from "~/transport/channel";

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

describe("createTransport", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test("subscribes to channel events and returns an unsubscribe function", () => {
    const transport = createTransport({
      topic: "room:test-room",
    });
    const channel = socket.channel.mock.results.at(-1).value;
    const handler = vi.fn();

    channel.on.mockImplementationOnce(() => 7);

    const unsubscribe = transport.subscribe("state", handler);

    expect(channel.on).toHaveBeenCalledWith("state", handler);

    unsubscribe();

    expect(channel.off).toHaveBeenCalledWith("state", 7);
  });

  test("registers join receive handlers", () => {
    const transport = createTransport({
      topic: "room:test-room",
    });

    void transport.join();

    const channel = socket.channel.mock.results.at(-1).value;
    const push = channel.join.mock.results[0].value;

    expect(channel.join).toHaveBeenCalledTimes(1);
    expect(push.receive).toHaveBeenCalledWith("ok", expect.any(Function));
    expect(push.receive).toHaveBeenCalledWith("error", expect.any(Function));
    expect(push.receive).toHaveBeenCalledWith("timeout", expect.any(Function));
  });

  test("registers push receive handlers", () => {
    const transport = createTransport({
      topic: "room:test-room",
    });

    void transport.join();
    void transport.push("advance_turn", {});

    const channel = socket.channel.mock.results.at(-1).value;
    const push = channel.push.mock.results[0].value;

    expect(channel.push).toHaveBeenCalledWith("advance_turn", {}, undefined);
    expect(push.receive).toHaveBeenCalledWith("ok", expect.any(Function));
    expect(push.receive).toHaveBeenCalledWith("error", expect.any(Function));
    expect(push.receive).toHaveBeenCalledWith("timeout", expect.any(Function));
  });

  test("registers close and error handlers", () => {
    const onClose = vi.fn();
    const onError = vi.fn();
    const transport = createTransport({
      topic: "room:test-room",
      onClose,
      onError,
    });

    const channel = socket.channel.mock.results.at(-1).value;
    const closeHandler = channel.onClose.mock.calls[0]?.[0];
    const errorHandler = channel.onError.mock.calls[0]?.[0];

    expect(closeHandler).toEqual(expect.any(Function));
    expect(errorHandler).toEqual(expect.any(Function));

    closeHandler("closed", 1, 2);
    expect(transport.status).toBe("failed");
    expect(onClose).toHaveBeenCalledWith("closed", 1, 2);

    errorHandler("boom");
    expect(onError).toHaveBeenCalledWith("boom");
  });

  test("disposes the channel only once", () => {
    const transport = createTransport({
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results.at(-1).value;

    transport.dispose();
    transport.dispose();

    expect(channel.leave).toHaveBeenCalledTimes(1);
  });

  test("tracks join lifecycle state", async () => {
    const transport = createTransport({
      topic: "room:test-room",
    });
    const channel = socket.channel.mock.results.at(-1).value;

    expect(transport.status).toBe("idle");

    const pending = transport.join();
    const push = channel.join.mock.results[0].value;
    const okHandler = getReceiveHandler(push, "ok");

    expect(transport.status).toBe("joining");

    okHandler();

    await expect(pending).resolves.toEqual({
      status: "ok",
      response: undefined,
    });
    expect(transport.status).toBe("active");
    expect(channel.join).toHaveBeenCalledTimes(1);
  });

  test("tracks failed join lifecycle state", async () => {
    const transport = createTransport({
      topic: "room:test-room",
    });
    const pending = transport.join();
    const channel = socket.channel.mock.results.at(-1).value;
    const push = channel.join.mock.results[0].value;
    const errorHandler = getReceiveHandler(push, "error");

    errorHandler({ reason: "game_not_found" });

    await expect(pending).resolves.toEqual({
      status: "error",
      response: { reason: "game_not_found" },
    });
    expect(transport.status).toBe("failed");
  });

  test("rejects push before join", () => {
    const transport = createTransport({
      topic: "room:test-room",
    });

    expect(() => transport.push("advance_turn", {})).toThrow(
      "Transport cannot push before join",
    );
  });
});
