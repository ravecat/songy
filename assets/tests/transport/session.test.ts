import { get } from "svelte/store";
import { beforeEach, describe, expect, test, vi } from "vitest";
import socket from "~/transport/socket";
import { createSession } from "~/transport/session";

vi.mock("~/transport/socket", async () => {
  const { Socket } = await import("../../__mocks__/phoenix.js");

  return {
    default: new Socket("/socket", {}),
  };
});

interface CounterSessionSpec {
  snapshot: {
    count: number;
  };
  connect: {
    ok: {
      count: number;
    };
    error: {
      reason: string;
    };
  };
  events: {
    replace: {
      count: number;
    };
    increment: {
      amount: number;
    };
  };
  commands: {
    ping: {
      event: "ping";
    };
    setCount: {
      event: "set_count";
      payload: {
        count: number;
      };
    };
    save: {
      event: "save";
      payload: {
        count: number;
      };
      reply: {
        accepted: string;
        validation_failed: string;
        timeout: string;
      };
    };
  };
}

type CounterSessionConfig =
  Parameters<typeof createSession<CounterSessionSpec>>[0];

function getChannel() {
  const channel = vi.mocked(socket.channel).mock.results.at(-1)?.value;

  if (!channel) {
    throw new Error("Expected channel to be created");
  }

  return channel;
}

function getReceiveHandler(push: { receive: { mock: { calls: Array<[string, (payload?: unknown) => void]> } } }, status: string) {
  return [...push.receive.mock.calls]
    .reverse()
    .find(([currentStatus]) => currentStatus === status)?.[1];
}

function triggerReply(
  push: { receive: { mock: { calls: Array<[string, (payload?: unknown) => void]> } } },
  status: string,
  payload?: unknown,
) {
  const handler = getReceiveHandler(push, status);

  if (!handler) {
    throw new Error(`Expected ${status} handler to be registered`);
  }

  handler(payload);
}

function triggerJoin(channel: ReturnType<typeof getChannel>, status: string, payload?: unknown) {
  const push = channel.join.mock.results.at(-1)?.value;

  if (!push) {
    throw new Error("Expected join push to be created");
  }

  triggerReply(push, status, payload);
}

function emitEvent(channel: ReturnType<typeof getChannel>, event: string, payload: unknown) {
  const handler = [...channel.on.mock.calls]
    .reverse()
    .find(([currentEvent]) => currentEvent === event)?.[1];

  if (!handler) {
    throw new Error(`Expected ${event} handler to be registered`);
  }

  handler(payload);
}

function emitTransportError(channel: ReturnType<typeof getChannel>, error?: unknown) {
  const handler = channel.onError.mock.calls.at(-1)?.[0];

  if (!handler) {
    throw new Error("Expected transport error handler to be registered");
  }

  handler(error);
}

function emitTransportClose(channel: ReturnType<typeof getChannel>) {
  const handler = channel.onClose.mock.calls.at(-1)?.[0];

  if (!handler) {
    throw new Error("Expected transport close handler to be registered");
  }

  handler(undefined, undefined, undefined);
}

function getLastPush(channel: ReturnType<typeof getChannel>) {
  const push = channel.push.mock.results.at(-1)?.value;
  const lastCall = channel.push.mock.calls.at(-1);

  if (!push || !lastCall) {
    throw new Error("Expected a push to be recorded");
  }

  const [event, payload] = lastCall;

  return {
    event,
    payload,
    push,
  };
}

async function flushMicrotasks() {
  await Promise.resolve();
  await Promise.resolve();
}

function config(
  overrides: Partial<CounterSessionConfig> = {},
) {
  return {
    topic: "room:test-room",
    events: {
      replace: (_snapshot, payload) => payload,
      increment: (snapshot, payload) => ({
        ...snapshot,
        count: snapshot.count + payload.amount,
      }),
    },
    commands: {
      ping: {
        event: "ping",
      },
      setCount: {
        event: "set_count",
      },
      save: {
        event: "save",
        accepted: (reply) => (reply as { id: string }).id,
        validation_failed: (reply) => (reply as { reason: string }).reason,
        timeout: () => "timed_out",
      },
    },
    ...overrides,
  } satisfies CounterSessionConfig;
}

describe("createSession", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test("starts in loading state and joins on first subscribe", () => {
    const session = createSession<CounterSessionSpec>(config());
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    expect(get(session)).toEqual({
      snapshot: null,
      status: "loading",
      error: null,
    });
    expect(socket.channel).toHaveBeenCalledWith("room:test-room", {});
    expect(channel.join).toHaveBeenCalledTimes(1);

    unsubscribe();
  });

  test("supports snapshot before connect reply arrives", () => {
    const session = createSession<CounterSessionSpec>(config({
      snapshot: { count: 2 },
    }));
    const unsubscribe = session.subscribe(() => { });

    expect(get(session)).toEqual({
      snapshot: { count: 2 },
      status: "ready",
      error: null,
    });

    unsubscribe();
  });

  test("lets connect.ok derive from current snapshot", async () => {
    const session = createSession<CounterSessionSpec>(config({
      snapshot: { count: 2 },
      connect: {
        ok: (snapshot, reply) => ({
          count: (snapshot?.count ?? 0) + reply.count,
        }),
      },
    }));
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    expect(get(session)).toEqual({
      snapshot: { count: 2 },
      status: "ready",
      error: null,
    });

    triggerJoin(channel, "ok", { count: 3 });
    await flushMicrotasks();

    expect(get(session)).toEqual({
      snapshot: { count: 5 },
      status: "ready",
      error: null,
    });

    unsubscribe();
  });

  test("maps connect error into session error and failed status", async () => {
    const session = createSession<CounterSessionSpec>(config({
      connect: {
        error: (reply) => new Error(reply.reason),
      },
    }));
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    triggerJoin(channel, "error", { reason: "game_not_found" });
    await flushMicrotasks();

    expect(get(session)).toMatchObject({
      snapshot: null,
      status: "failed",
      error: {
        kind: "connect_error",
        cause: expect.any(Error),
      },
    });

    unsubscribe();
  });

  test("uses default timeout error for connect timeout", async () => {
    const session = createSession<CounterSessionSpec>(config());
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    triggerJoin(channel, "timeout");
    await flushMicrotasks();

    expect(get(session)).toMatchObject({
      snapshot: null,
      status: "failed",
      error: {
        kind: "connect_timeout",
        cause: expect.any(Error),
      },
    });

    unsubscribe();
  });

  test("event reducers update snapshot while session is ready", async () => {
    const session = createSession<CounterSessionSpec>(config());
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    triggerJoin(channel, "ok", { count: 1 });
    await flushMicrotasks();

    emitEvent(channel, "increment", { amount: 2 });

    expect(get(session)).toEqual({
      snapshot: { count: 3 },
      status: "ready",
      error: null,
    });

    unsubscribe();
  });

  test("event reducers clear transport degradation after a stale transition", async () => {
    const session = createSession<CounterSessionSpec>(config());
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    triggerJoin(channel, "ok", { count: 1 });
    await flushMicrotasks();
    emitTransportError(channel, new Error("socket down"));

    expect(get(session)).toMatchObject({
      snapshot: { count: 1 },
      status: "stale",
      error: {
        kind: "transport_error",
      },
    });

    emitEvent(channel, "replace", { count: 4 });

    expect(get(session)).toEqual({
      snapshot: { count: 4 },
      status: "ready",
      error: null,
    });

    unsubscribe();
  });

  test("transport close without snapshot fails the session", () => {
    const session = createSession<CounterSessionSpec>(config());
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    emitTransportClose(channel);

    expect(get(session)).toEqual({
      snapshot: null,
      status: "failed",
      error: {
        kind: "transport_close",
      },
    });

    unsubscribe();
  });

  test("signal commands push and return void", async () => {
    const session = createSession<CounterSessionSpec>(config());
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    triggerJoin(channel, "ok", { count: 1 });
    await flushMicrotasks();

    expect(session.commands.ping()).toBeUndefined();
    expect(getLastPush(channel)).toMatchObject({
      event: "ping",
      payload: {},
    });

    unsubscribe();
  });

  test("signal commands pass object payload through by default", async () => {
    const session = createSession<CounterSessionSpec>(config());
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    triggerJoin(channel, "ok", { count: 1 });
    await flushMicrotasks();

    expect(session.commands.setCount({ count: 9 })).toBeUndefined();
    expect(getLastPush(channel)).toMatchObject({
      event: "set_count",
      payload: { count: 9 },
    });

    unsubscribe();
  });

  test("reply-aware commands resolve mapped reply envelopes", async () => {
    const session = createSession<CounterSessionSpec>(config());
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    triggerJoin(channel, "ok", { count: 1 });
    await flushMicrotasks();

    const pending = session.commands.save({ count: 5 });

    expect(getLastPush(channel)).toMatchObject({
      event: "save",
      payload: { count: 5 },
    });

    triggerReply(getLastPush(channel).push, "accepted", { id: "message-1" });

    await expect(pending).resolves.toEqual({
      status: "accepted",
      payload: "message-1",
    });

    unsubscribe();
  });

  test("reply-aware commands keep arbitrary statuses as resolved results", async () => {
    const session = createSession<CounterSessionSpec>(config());
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    triggerJoin(channel, "ok", { count: 1 });
    await flushMicrotasks();

    const pending = session.commands.save({ count: 5 });

    triggerReply(getLastPush(channel).push, "validation_failed", {
      reason: "too_early",
    });

    await expect(pending).resolves.toEqual({
      status: "validation_failed",
      payload: "too_early",
    });

    unsubscribe();
  });

  test("last unsubscribe removes local handlers before leave", async () => {
    const session = createSession<CounterSessionSpec>(config());
    const unsubscribe = session.subscribe(() => { });
    const channel = getChannel();

    triggerJoin(channel, "ok", { count: 2 });
    await flushMicrotasks();

    unsubscribe();

    expect(channel.off.mock.calls.map((call: [string, unknown?]) => call[0])).toEqual([
      "phx_error",
      "phx_close",
      "replace",
      "increment",
    ]);
    expect(channel.leave).toHaveBeenCalledTimes(1);
    expect(Math.max(...channel.off.mock.invocationCallOrder)).toBeLessThan(
      channel.leave.mock.invocationCallOrder[0],
    );
  });
});
