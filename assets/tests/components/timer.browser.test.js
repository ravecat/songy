import Room from "~pages/room.svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { users } from "~fixtures/users";
import { render } from "../inertia";

describe("Timer", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  test("does not render outside the challenging phase", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-ready",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect.element(screen.getByRole("timer")).not.toBeInTheDocument();
  });

  test("renders remaining seconds", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-timer",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect.element(screen.getByRole("timer")).toHaveTextContent("12");
  });

  test("counts down locally from deadline_at_ms", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-timer",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    const timer = screen.getByRole("timer");

    await expect.element(timer).toHaveTextContent("12");
    await vi.advanceTimersByTimeAsync(1_000);
    await expect.element(timer).toHaveTextContent("11");
  });
});
