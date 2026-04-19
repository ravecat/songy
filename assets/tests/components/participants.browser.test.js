import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { users } from "~fixtures/users";
import { render } from "../inertia";

const playerCount = Object.keys(users).length;

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
      .element(screen.getByRole("status", { name: `${playerCount} players online` }))
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

    const status = screen.getByRole("status", { name: "1 player online" });

    expect(status.element().querySelectorAll("img")).toHaveLength(1);
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

  test("renders up to three participant avatars from the queue", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-player-lobby",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    const status = screen.getByRole("status", {
      name: `${playerCount} players online`,
    });

    await expect.element(status).toBeVisible();

    const avatars = Array.from(status.element().querySelectorAll("img"));

    expect(avatars).toHaveLength(3);
    expect(avatars.map((avatar) => avatar.getAttribute("src"))).toEqual([
      users.alice.avatar_url,
      users.bob.avatar_url,
      users.carol.avatar_url,
    ]);
    expect(status.element().textContent).toContain(String(playerCount));
  });
});
