import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { render } from "../inertia";

describe("room page", () => {
  test("shows the loader before the room session joins", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-1",
        scope: {
          user: {
            uuid: "user-1",
            name: "Alice",
          },
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("status", { name: "loading" }))
      .toBeVisible();
  });

  test("renders the lobby after phx_join succeeds", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-1",
        scope: {
          user: {
            uuid: "user-1",
            name: "Alice",
          },
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Lobby players" }))
      .toBeVisible();
    await expect.element(screen.getByText("Alice")).toBeVisible();
    await expect
      .element(screen.getByRole("button", { name: "Copy share link" }))
      .toBeVisible();
  });
});
