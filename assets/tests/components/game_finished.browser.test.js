import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { users } from "../mock/room/fixtures";
import { render } from "../inertia";

describe("GameFinished", () => {
  test("shows winner and target score", async () => {
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
    await expect.element(screen.getByText("10/10 points")).toBeVisible();
    await expect.element(screen.getByText("Target 10")).toBeVisible();
  });

  test("sorts leaderboard by score descending", async () => {
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
      .element(screen.getByRole("list", { name: "Final leaderboard" }))
      .toBeVisible();

    const leaderboard = Array.from(document.body.querySelectorAll(".game-finished__entry"));

    expect(leaderboard).toHaveLength(3);
    expect(leaderboard[0]?.textContent).toContain("Bob");
    expect(leaderboard[1]?.textContent).toContain("Alice");
    expect(leaderboard[2]?.textContent).toContain("Carol");
    expect(leaderboard[0]?.getAttribute("aria-current")).toBe("true");
  });

  test("falls back to user id when participant payload is missing", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-finished-missing-participant",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Final leaderboard" }))
      .toBeVisible();

    const leaderboard = Array.from(document.body.querySelectorAll(".game-finished__entry"));
    const missingParticipantRow = leaderboard[2];

    expect(missingParticipantRow?.textContent).toContain(users.carol.uuid);
    expect(
      missingParticipantRow?.querySelector(".game-finished__entry-score")?.textContent,
    ).toBe("3");
  });
});
