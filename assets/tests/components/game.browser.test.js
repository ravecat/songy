import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { users } from "../mock/room/fixtures";
import { render } from "../inertia";

describe("Game", () => {
  test("renders timeline details for the active player in ready phase", async () => {
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
      .element(screen.getByRole("list", { name: "Timeline" }))
      .toBeVisible();
    expect(document.body.textContent).toContain("Timeline Track 1");
    expect(document.body.textContent).toContain("Artist 1");
    await expect.element(screen.getByText("2020")).toBeVisible();
  });

  test("renders timeline details for a passive player in ready phase", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-ready",
        scope: {
          user: users.bob,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Timeline" }))
      .toBeVisible();
    expect(document.body.textContent).toContain("Timeline Track 1");
    expect(document.body.textContent).toContain("Artist 1");
    await expect.element(screen.getByText("2020")).toBeVisible();
  });

  test("displays waiting view on waiting phase", async () => {
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
  });

  test("displays waiting view for a passive player", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-waiting-passive",
        scope: {
          user: users.bob,
          provider: null,
        },
      },
    });

    await expect.element(screen.getByText("Alice turn")).toBeVisible();
  });

  test("displays results view on results phase", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-results",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect.element(screen.getByText("Queen")).toBeVisible();
    await expect.element(screen.getByText("Bohemian Rhapsody")).toBeVisible();
    await expect.element(screen.getByText("1975")).toBeVisible();
  });

  test("displays finished view on finished status even with stale results phase", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-finished",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("heading", { name: "Bob wins" }))
      .toBeVisible();
    await expect
      .element(screen.getByRole("list", { name: "Final leaderboard" }))
      .toBeVisible();
    await expect.element(screen.getByText("Queen")).not.toBeInTheDocument();
  });

  test.each(invalidPhaseRoomIds)(
    "renders no phase-specific view for invalid phase room: %s",
    async (roomId) => {
      const screen = render(Room, {
        props: {
          roomId,
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      await expect
        .element(screen.getByRole("region", { name: "Turn waiting" }))
        .not.toBeInTheDocument();
      await expect
        .element(screen.getByRole("list", { name: "Result challengers" }))
        .not.toBeInTheDocument();
      await expect
        .element(screen.getByRole("list", { name: "Lobby players" }))
        .not.toBeInTheDocument();
    },
  );
});

const invalidPhaseRoomIds = [
  "room-invalid-phase-0",
  "room-invalid-phase-1",
  "room-invalid-phase-2",
  "room-invalid-phase-3",
  "room-invalid-phase-4",
  "room-invalid-phase-5",
  "room-invalid-phase-6",
  "room-invalid-phase-7",
];
