import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { users } from "~fixtures/users";
import { render } from "../inertia";

describe("Turn waiting view", () => {
  test("displays personalized message when current user is active player", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-waiting-active",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect.element(screen.getByText("It's your turn")).toBeVisible();
    await expect.element(screen.getByAltText(users.alice.name)).toHaveAttribute(
      "src",
      users.alice.avatar_url,
    );
  });

  test("displays passive message when another user is active", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-waiting-passive",
        scope: {
          user: users.bob,
          provider: null,
        },
      },
    });

    await expect.element(screen.getByText(`${users.alice.name} turn`)).toBeVisible();
    await expect.element(screen.getByAltText(users.alice.name)).toHaveAttribute(
      "src",
      users.alice.avatar_url,
    );
  });

  test("displays second player when cursor is 1", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-waiting-active-bob",
        scope: {
          user: users.bob,
          provider: null,
        },
      },
    });

    await expect.element(screen.getByText("It's your turn")).toBeVisible();
    await expect.element(screen.getByAltText(users.bob.name)).toHaveAttribute(
      "src",
      users.bob.avatar_url,
    );
  });

  test("shows active player info for a different viewer when cursor is 1", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-waiting-passive-bob",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect.element(screen.getByText(`${users.bob.name} turn`)).toBeVisible();
    await expect.element(screen.getByAltText(users.bob.name)).toHaveAttribute(
      "src",
      users.bob.avatar_url,
    );
  });

  test("displays passive message for the owner when another player is active", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-waiting-active-bob",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect.element(screen.getByText(`${users.bob.name} turn`)).toBeVisible();
    await expect.element(screen.getByText("It's your turn")).not.toBeInTheDocument();
    await expect.element(screen.getByAltText(users.bob.name)).toHaveAttribute(
      "src",
      users.bob.avatar_url,
    );
  });
});
