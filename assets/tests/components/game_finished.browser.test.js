import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import {
  finishedMissingParticipantSnapshot,
  finishedSnapshot,
} from "~fixtures/room/messages";
import { users } from "~fixtures/users";
import { render } from "../inertia";

const finishedWinner = finishedSnapshot.game.participants[finishedSnapshot.game.turn.winner_id];
const finishedWinnerScore = finishedSnapshot.game.scores[finishedSnapshot.game.turn.winner_id];
const finishedMissingParticipantScore =
  finishedMissingParticipantSnapshot.game.scores[users.carol.id];

describe("GameFinished", () => {
  test("shows winner", async () => {
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
      .element(screen.getByRole("heading", { name: `${finishedWinner.name} wins` }))
      .toBeVisible();
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
    const renderedScores = leaderboard.map((entry) =>
      Number(entry.querySelector(".game-finished__entry-score")?.textContent),
    );

    expect(leaderboard).toHaveLength(Object.keys(finishedSnapshot.game.scores).length);
    expect(leaderboard[0]?.textContent).toContain(finishedWinner.name);
    expect(leaderboard[0]?.textContent).toContain(String(finishedWinnerScore));
    expect(leaderboard[0]?.getAttribute("aria-current")).toBe("true");
    expect(renderedScores).toEqual([...renderedScores].sort((left, right) => right - left));

    for (const [userId, score] of Object.entries(finishedSnapshot.game.scores)) {
      const name = finishedSnapshot.game.participants[userId]?.name ?? userId;
      const matchingEntry = leaderboard.find(
        (entry) =>
          entry.textContent?.includes(name) &&
          entry.querySelector(".game-finished__entry-score")?.textContent === String(score),
      );

      expect(matchingEntry).toBeDefined();
    }
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
    const missingParticipantRow = leaderboard.find((entry) =>
      entry.textContent?.includes(users.carol.id),
    );

    expect(missingParticipantRow?.textContent).toContain(users.carol.id);
    expect(
      missingParticipantRow?.querySelector(".game-finished__entry-score")?.textContent,
    ).toBe(String(finishedMissingParticipantScore));
  });
});
