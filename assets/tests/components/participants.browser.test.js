import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { users } from "~fixtures/users";
import { render } from "../inertia";

describe("Participants component", () => {
  test("displays correct participant count", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-player-lobby",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("status", { name: "3 players online" }))
      .toBeVisible();
  });

  test("displays 0 when no participants", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-empty-lobby",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("status", { name: "0 players online" }))
      .toBeVisible();
  });

  test("displays 1 player singular form", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-single-player",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("status", { name: "1 player online" }))
      .toBeVisible();
  });

  test("handles undefined participants gracefully", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-undefined-participants",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("status", { name: "0 players online" }))
      .toBeVisible();
  });

  test("renders Users icon", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-player-lobby",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("status", { name: "3 players online" }))
      .toBeVisible();
    expect(document.body.querySelector("svg.lucide-users")).not.toBeNull();
  });
});
