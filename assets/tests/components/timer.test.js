import { render, screen } from "@testing-library/svelte";
import { tick } from "svelte";
import { afterEach, describe, expect, test, vi } from "vitest";
import TimerProviderFixture from "../fixtures/timer_provider_fixture.svelte";
import socket from "~/socket";

vi.mock("~/socket", async () => {
  const { Socket } = await import("phoenix");

  return {
    default: new Socket("/socket", {}),
  };
});

function buildStatePayload(phase = "challenging") {
  return {
    game: {
      id: "game-1",
      owner_id: "owner-1",
      max_participants: 8,
      max_score: 10,
      status: "in_progress",
      participants: {},
      scores: {},
      player: null,
      timelines: {},
      created_at: "2026-01-01T00:00:00Z",
      queue: [],
      cursor: 0,
      track: null,
      turn: {
        phase,
        assumptions: {},
        winner_id: null,
      },
    },
    permissions: {
      can_control_playback: false,
      can_advance_turn: false,
      can_start_game: false,
      can_start_turn: false,
      can_restart_game: false,
      can_see_assumptions: false,
      can_make_assumptions: false,
    },
  };
}

describe("Timer", () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  test("does not render when seconds is null", async () => {
    render(TimerProviderFixture, {
      socket,
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results[0].value;
    const push = channel.join.mock.results[0].value;
    const okHandler = push.receive.mock.calls.find(
      ([status]) => status === "ok",
    )?.[1];

    okHandler(buildStatePayload());
    await tick();

    expect(screen.queryByRole("timer")).not.toBeInTheDocument();
  });

  test("renders remaining seconds", async () => {
    render(TimerProviderFixture, {
      socket,
      topic: "room:test-room",
    });

    const channel = socket.channel.mock.results[0].value;
    const push = channel.join.mock.results[0].value;
    const okHandler = push.receive.mock.calls.find(
      ([status]) => status === "ok",
    )?.[1];
    const timerHandler = channel.on.mock.calls.find(
      ([event]) => event === "timer",
    )?.[1];

    okHandler(buildStatePayload());
    timerHandler({ remaining: 12 });
    await tick();

    expect(screen.getByRole("timer")).toHaveTextContent("12");
  });
});
