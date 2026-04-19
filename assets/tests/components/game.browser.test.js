import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { tracks } from "~fixtures/tracks";
import { users } from "~fixtures/users";
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
    expect(document.body.textContent).toContain(tracks.timelineOne.title);
    expect(document.body.textContent).toContain(tracks.timelineOne.artist);
    await expect
      .element(screen.getByText(String(tracks.timelineOne.year)))
      .toBeVisible();
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
    expect(document.body.textContent).toContain(tracks.timelineOne.title);
    expect(document.body.textContent).toContain(tracks.timelineOne.artist);
    await expect
      .element(screen.getByText(String(tracks.timelineOne.year)))
      .toBeVisible();
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

    await expect.element(screen.getByText(`${users.alice.name} turn`)).toBeVisible();
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

    await expect.element(screen.getByText(tracks.result.title)).toBeVisible();
    await expect.element(screen.getByText(String(tracks.result.year))).toBeVisible();
    expect(document.body.textContent).toContain(tracks.result.artist);
    expect(document.body.textContent).toContain(tracks.result.title);
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
      .element(screen.getByRole("heading", { name: `${users.bob.name} wins` }))
      .toBeVisible();
    await expect
      .element(screen.getByRole("list", { name: "Final leaderboard" }))
      .toBeVisible();
    expect(document.body.textContent).not.toContain(tracks.result.artist);
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
        .element(screen.getByRole("button", { name: "Copy share link" }))
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
