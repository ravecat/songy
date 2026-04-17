import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { tracks } from "~fixtures/tracks";
import { users } from "~fixtures/users";
import { render } from "../inertia";

describe("Player", () => {
  test("renders player controls group", async () => {
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
      .element(screen.getByRole("group", { name: "Player controls" }))
      .toBeVisible();
  });

  test("always renders the play button in the center slot", async () => {
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
      .element(screen.getByRole("button", { name: "Play track" }))
      .toBeVisible();
  });

  test("shows start game button for the owner in lobby", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-owner-lobby",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("button", { name: "Start game" }))
      .toBeEnabled();
  });

  test("starts the game from the lobby without mocking session methods", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-start-game",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await screen.getByRole("button", { name: "Start game" }).click();

    await expect
      .element(screen.getByRole("button", { name: "Ready" }))
      .toBeVisible();
    await expect.element(screen.getByText("It's your turn")).toBeVisible();
  });

  test("shows a disabled forward button for challengers in lobby", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-player-lobby",
        scope: {
          user: users.bob,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("button", { name: "Forward" }))
      .toBeDisabled();
  });

  test("advances the turn when ready is clicked", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-advance-turn",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await screen.getByRole("button", { name: "Ready" }).click();

    await expect
      .element(screen.getByRole("button", { name: "Forward" }))
      .toBeDisabled();
    await expect
      .element(screen.getByRole("list", { name: "Timeline" }))
      .toBeVisible();
    expect(document.body.textContent).toContain(tracks.timelineOne.title);
  });

  test("disables the play button when playback control is unavailable", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-ready",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("button", { name: "Play track" }))
      .toBeDisabled();
  });

  test("enables the play button when playback control is available", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-ready-controls",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("button", { name: "Play track" }))
      .toBeEnabled();
  });

  test("shows play again button for a finished game", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-finished-restart",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("button", { name: "Play again" }))
      .toBeEnabled();
  });

  test("sets aria-pressed=false when not playing", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-ready",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("button", { name: "Play track" }))
      .toHaveAttribute("aria-pressed", "false");
  });

  test("sets aria-pressed=true when playing", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-ready-playing",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("button", { name: "Pause track" }))
      .toHaveAttribute("aria-pressed", "true");
  });

  test("pushes start_playback through the room topic", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-start-playback",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await screen.getByRole("button", { name: "Play track" }).click();

    await expect
      .element(screen.getByRole("button", { name: "Pause track" }))
      .toBeVisible();
  });

  test("pushes pause_playback through the room topic", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-pause-playback",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await screen.getByRole("button", { name: "Pause track" }).click();

    await expect
      .element(screen.getByRole("button", { name: "Play track" }))
      .toBeVisible();
  });
});
