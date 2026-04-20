import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import {
  resultsNoWinnerSnapshot,
  resultsActivePlayerWinsSnapshot,
} from "~fixtures/room/messages";
import { tracks } from "~fixtures/tracks";
import { users } from "~fixtures/users";
import { render } from "../inertia";

const resultsAssumptionIds = Object.values(resultsActivePlayerWinsSnapshot.game.turn.assumptions);
const resultsChallengers = resultsAssumptionIds
  .map((userId) => resultsActivePlayerWinsSnapshot.game.participants[userId])
  .filter(Boolean);
const resultsNonChallengers = Object.values(resultsActivePlayerWinsSnapshot.game.participants).filter(
  (user) => !resultsAssumptionIds.includes(user.id),
);
const resultsWinner =
  resultsActivePlayerWinsSnapshot.game.participants[
    resultsActivePlayerWinsSnapshot.game.turn.winner_id
  ];

const noWinnerAssumptionIds = Object.values(resultsNoWinnerSnapshot.game.turn.assumptions);
const noWinnerChallengers = noWinnerAssumptionIds
  .map((userId) => resultsNoWinnerSnapshot.game.participants[userId])
  .filter(Boolean);

describe("TurnResults", () => {
  test("renders track info", async () => {
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

  test("displays challenger avatars", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-results",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    const challengersList = screen.getByRole("list", { name: "Result challengers" });

    for (const user of resultsChallengers) {
      await expect.element(challengersList.getByAltText(user.name)).toHaveAttribute(
        "src",
        user.avatar_url,
      );
    }

    for (const user of resultsNonChallengers) {
      await expect.element(challengersList.getByAltText(user.name)).not.toBeInTheDocument();
    }
  });

  test("displays challenger names", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-results",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    const challengersList = screen.getByRole("list", { name: "Result challengers" });

    for (const user of resultsChallengers) {
      await expect.element(challengersList.getByText(user.name)).toBeVisible();
    }
  });

  test("highlights the winner with a score badge", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-results",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Result challengers" }))
      .toBeVisible();

    const renderedChallengers = Array.from(document.body.querySelectorAll(".results__challenger"));
    const winner = renderedChallengers.find(
      (challenger) => challenger.getAttribute("aria-current") === "true",
    );

    expect(winner).toBeDefined();
    expect(winner?.textContent).toContain(resultsWinner.name);
    expect(winner?.textContent).toContain("+1");
  });

  test("marks only one challenger as winner", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-results",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Result challengers" }))
      .toBeVisible();

    const renderedChallengers = Array.from(document.body.querySelectorAll(".results__challenger"));
    const winners = renderedChallengers.filter(
      (challenger) => challenger.getAttribute("aria-current") === "true",
    );

    expect(renderedChallengers).toHaveLength(resultsChallengers.length);
    expect(winners).toHaveLength(1);
  });

  test("handles missing winner without highlighting anyone", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-results-no-winner",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Result challengers" }))
      .toBeVisible();

    const renderedChallengers = Array.from(document.body.querySelectorAll(".results__challenger"));
    const winners = renderedChallengers.filter(
      (challenger) => challenger.getAttribute("aria-current") === "true",
    );

    expect(renderedChallengers).toHaveLength(noWinnerChallengers.length);
    expect(winners).toHaveLength(0);
    expect(document.body.textContent).not.toContain("+1");
  });
});
