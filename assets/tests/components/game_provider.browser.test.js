import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { users } from "~fixtures/users";
import { render } from "../inertia";

describe("game provider", () => {
  test("shows the loader before the room session joins", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-1",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("status", { name: "loading" }))
      .toBeVisible();
  });

  test("renders children after a successful join", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-1",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("button", { name: "Copy share link" }))
      .toBeVisible();
    await expect
      .element(screen.getByRole("status", { name: /players?\s+online/i }))
      .toBeVisible();
  });

  test("renders provider error when join fails", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-missing",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect.element(screen.getByRole("alert")).toBeVisible();
    await expect.element(screen.getByText("Room unavailable")).toBeVisible();
    await expect
      .element(screen.getByText("Reason: game_not_found"))
      .toBeVisible();
    await expect
      .element(screen.getByRole("link", { name: "Back home" }))
      .toHaveAttribute("href", "/");
  });
});
