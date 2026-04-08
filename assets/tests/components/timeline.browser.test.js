import Room from "~pages/room.svelte";
import { describe, expect, test } from "vitest";
import { users } from "../mock/room/fixtures";
import { render } from "../inertia";

function getHiddenCards(container) {
  return container.querySelectorAll(
    '[aria-label="Hidden track card"][aria-hidden="false"]',
  );
}

describe("Timeline", () => {
  test("shows an assumption card when can_make_assumptions is true", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-timeline-own-assumption",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Timeline" }))
      .toBeVisible();

    expect(getHiddenCards(document.body).length).toBeGreaterThanOrEqual(1);
  });

  test("hides assumption cards when can_make_assumptions is false", async () => {
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
    expect(document.body.textContent).toContain("Timeline Track 2");
    expect(getHiddenCards(document.body)).toHaveLength(0);
  });

  test("hides assumption cards when permissions are undefined", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-timeline-no-permissions",
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
    expect(getHiddenCards(document.body)).toHaveLength(0);
  });

  test("shows a track card for the current user in ready phase", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-timeline-own-assumption",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Timeline" }))
      .toBeVisible();

    expect(getHiddenCards(document.body)).toHaveLength(1);
  });

  test("shows the current user assumption in challenging phase", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-timeline-challenging-own",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Timeline" }))
      .toBeVisible();

    expect(getHiddenCards(document.body)).toHaveLength(1);
  });

  test("renders timeline tracks regardless of assumption permission", async () => {
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
    expect(document.body.textContent).toContain("Timeline Track 2");
    expect(document.body.textContent).toContain("Artist 1");
    expect(document.body.textContent).toContain("Artist 2");
  });

  test("handles missing current track gracefully", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-timeline-no-track",
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
    expect(getHiddenCards(document.body)).toHaveLength(0);
  });

  test("shows assumption card with user avatar in a placeholder slot", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-timeline-slot-zero",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Timeline" }))
      .toBeVisible();

    const avatars = document.body.querySelectorAll(
      `img[src="${users.alice.avatar_url}"]`,
    );

    expect(avatars.length).toBeGreaterThan(0);
  });

  describe("scroll snaps only to slots and own assumptions", () => {
    test("slots have data-snap", async () => {
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

      const snaps = document.body.querySelectorAll("[data-snap]");
      const slots = document.body.querySelectorAll("[data-position]:not(:has(img))");

      expect(snaps.length).toBe(3);
      expect(slots.length).toBe(3);

      slots.forEach((slot) => {
        expect(slot.hasAttribute("data-snap")).toBe(true);
      });
    });

    test("own assumption has data-snap", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-timeline-slot-zero",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      await expect
        .element(screen.getByLabelText("Alice's assumption"))
        .toHaveAttribute("data-snap");
    });

    test("other user assumption does not have data-snap", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-timeline-other-assumption",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      await expect
        .element(screen.getByLabelText("Bob's assumption"))
        .not.toHaveAttribute("data-snap");
    });

    test("track cells do not have data-snap", async () => {
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

      const allCells = document.body.querySelectorAll("[role='listitem']");
      const tracksWithSnap = Array.from(allCells).filter(
        (cell) => !cell.hasAttribute("data-position") && cell.hasAttribute("data-snap"),
      );

      expect(tracksWithSnap).toHaveLength(0);
    });

    test("mixed state keeps data-snap only on slots and own assumptions", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-timeline-mixed",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      await expect
        .element(screen.getByRole("list", { name: "Timeline" }))
        .toBeVisible();

      const snaps = document.body.querySelectorAll("[data-snap]");
      const snapPositions = Array.from(snaps).map((cell) => cell.dataset.position);

      expect(snapPositions).toContain("2");
      expect(snapPositions).toContain("3");
      expect(snapPositions).not.toContain("0");
    });
  });

  test("slot positions shift when assumptions exist", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-timeline-slot-zero",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Timeline" }))
      .toBeVisible();

    const slots = document.body.querySelectorAll("[data-position]");
    const positions = Array.from(slots).map((slot) => Number(slot.dataset.position));

    expect(slots).toHaveLength(3);
    expect(positions[0]).toBe(0);
    expect(positions[1]).toBe(1);
    expect(positions[2]).toBe(2);
  });
});
