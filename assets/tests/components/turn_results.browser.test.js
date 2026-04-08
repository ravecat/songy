import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { users } from "~fixtures/users";
import { render } from "../inertia";

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

    await expect.element(screen.getByText("Queen")).toBeVisible();
    await expect.element(screen.getByText("Bohemian Rhapsody")).toBeVisible();
    await expect.element(screen.getByText("1975")).toBeVisible();
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

    await expect.element(screen.getByAltText("Alice")).toHaveAttribute(
      "src",
      users.alice.avatar_url,
    );
    await expect.element(screen.getByAltText("Bob")).toHaveAttribute(
      "src",
      users.bob.avatar_url,
    );
    await expect.element(screen.getByAltText("Carol")).not.toBeInTheDocument();
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

    await expect.element(screen.getByText("Alice")).toBeVisible();
    await expect.element(screen.getByText("Bob")).toBeVisible();
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

    const challengers = Array.from(document.body.querySelectorAll(".results__challenger"));
    const winner = challengers.find(
      (challenger) => challenger.getAttribute("aria-current") === "true",
    );

    expect(winner).toBeDefined();
    expect(document.body.textContent).toContain("+1");
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

    const challengers = Array.from(document.body.querySelectorAll(".results__challenger"));
    const winners = challengers.filter(
      (challenger) => challenger.getAttribute("aria-current") === "true",
    );

    expect(challengers).toHaveLength(2);
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

    const challengers = Array.from(document.body.querySelectorAll(".results__challenger"));
    const winners = challengers.filter(
      (challenger) => challenger.getAttribute("aria-current") === "true",
    );

    expect(winners).toHaveLength(0);
    expect(document.body.textContent).not.toContain("+1");
  });
});
