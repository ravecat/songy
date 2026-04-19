import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { users } from "~fixtures/users";
import { render } from "../inertia";

describe("Score", () => {
  test("renders score from room session", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-score-3",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("img", { name: "Your score: 3" }))
      .toBeVisible();
  });

  test("returns 0 when user score is not defined", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-score-missing",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("img", { name: "Your score: 0" }))
      .toBeVisible();
  });

  test("returns 0 when scores object is undefined", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-score-undefined",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("img", { name: "Your score: 0" }))
      .toBeVisible();
  });
});
