import { writable } from "svelte/store";
import { render } from "vitest-browser-svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { currentUser } from "~/stores/scope";

vi.mock("~/contexts/game");

vi.mock("~/stores/scope", async () => {
  const { writable } = await import("svelte/store");

  return {
    currentUser: writable(null),
    provider: writable(undefined),
  };
});

import Timeline from "~components/timeline.svelte";
import { getGameContext } from "~/contexts/game";

describe("Timeline", () => {
  let mockGameContext;

  beforeEach(() => {
    vi.clearAllMocks();

    mockGameContext = {
      snapshot: {
        game: {
          track: {
            id: "track-123",
            title: "Current Track",
            artist: "Current Artist",
            year: 2024,
            cover_url: null,
            meta: {},
          },
          participants: {
            "current-user-123": {
              uuid: "current-user-123",
              name: "Test User",
              avatar_url: "https://example.com/avatar.jpg",
            },
            "user-1": {
              uuid: "user-1",
              name: "User 1",
              avatar_url: "https://example.com/user-1.jpg",
            },
          },
          queue: ["current-user-123", "user-1"],
          cursor: 0,
          timelines: {
            "current-user-123": [
              {
                id: "timeline-1",
                title: "Timeline Track 1",
                artist: "Artist 1",
                year: 2020,
                cover_url: null,
                meta: {},
              },
              {
                id: "timeline-2",
                title: "Timeline Track 2",
                artist: "Artist 2",
                year: 2021,
                cover_url: null,
                meta: {},
              },
            ],
          },
          turn: {
            phase: "ready",
            assumptions: {},
            winner_id: null,
          },
        },
        permissions: {
          can_control_playback: false,
          can_advance_turn: false,
          can_start_game: false,
          can_start_turn: false,
          can_restart_game: false,
          can_see_assumptions: false,
          can_make_assumptions: false,
        },
      },
      status: "ready",
      error: null,
    };

    currentUser.set({
      uuid: "current-user-123",
      name: "Test User",
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("shows track card when can_make_assumptions is true", () => {
    mockGameContext.snapshot.permissions.can_make_assumptions = true;
    mockGameContext.snapshot.game.turn.assumptions = {
      "1": "current-user-123",
    };
    mockGameContext.snapshot.game.timelines["current-user-123"] = [
      mockGameContext.snapshot.game.timelines["current-user-123"][0],
      mockGameContext.snapshot.game.track,
      mockGameContext.snapshot.game.timelines["current-user-123"][1],
    ];

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    const hiddenCards = container.querySelectorAll(
      '[aria-label="Hidden track card"][aria-hidden="false"]',
    );
    expect(hiddenCards.length).toBeGreaterThanOrEqual(1);
  });

  test("hides track card when can_make_assumptions is false", () => {
    mockGameContext.snapshot.permissions.can_make_assumptions = false;

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    expect(container.textContent).toContain("Timeline Track 1");
    expect(container.textContent).toContain("Timeline Track 2");

    const hiddenCards = container.querySelectorAll(
      '[aria-label="Hidden track card"][aria-hidden="false"]',
    );
    expect(hiddenCards.length).toBe(0);
  });

  test("hides track card when permissions is undefined", () => {
    mockGameContext.snapshot.permissions = undefined;

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    expect(container.textContent).toContain("Timeline Track 1");
    expect(container.textContent).toContain("Timeline Track 2");

    const hiddenCards = container.querySelectorAll(
      '[aria-label="Hidden track card"][aria-hidden="false"]',
    );
    expect(hiddenCards.length).toBe(0);
  });

  test("hides track card when permissions is null", () => {
    mockGameContext.snapshot.permissions = null;

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    expect(container.textContent).toContain("Timeline Track 1");
    expect(container.textContent).toContain("Timeline Track 2");

    const hiddenCards = container.querySelectorAll(
      '[aria-label="Hidden track card"][aria-hidden="false"]',
    );
    expect(hiddenCards.length).toBe(0);
  });

  test("player in ready phase sees track card", () => {
    mockGameContext.snapshot.game.turn.phase = "ready";
    mockGameContext.snapshot.permissions.can_make_assumptions = true;
    mockGameContext.snapshot.game.turn.assumptions = {
      "1": "current-user-123",
    };

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    const hiddenCards = container.querySelectorAll(
      '[aria-label="Hidden track card"][aria-hidden="false"]',
    );
    expect(hiddenCards.length).toBe(1);
  });

  test("challenger in challenging phase sees track card", () => {
    mockGameContext.snapshot.game.turn.phase = "challenging";
    mockGameContext.snapshot.permissions.can_make_assumptions = true;
    mockGameContext.snapshot.game.queue = ["user-1", "current-user-123"];
    mockGameContext.snapshot.game.cursor = 0;
    mockGameContext.snapshot.game.turn.assumptions = {
      "1": "current-user-123",
    };
    mockGameContext.snapshot.game.timelines["user-1"] = [
      mockGameContext.snapshot.game.timelines["current-user-123"][0],
      mockGameContext.snapshot.game.timelines["current-user-123"][1],
    ];

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    const hiddenCards = container.querySelectorAll(
      '[aria-label="Hidden track card"][aria-hidden="false"]',
    );
    expect(hiddenCards.length).toBe(1);
  });

  test("no one sees track card in results phase", () => {
    mockGameContext.snapshot.game.turn.phase = "results";
    mockGameContext.snapshot.permissions.can_make_assumptions = false;
    mockGameContext.snapshot.permissions.can_see_assumptions = true;

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    const hiddenCards = container.querySelectorAll(
      '[aria-label="Hidden track card"][aria-hidden="false"]',
    );
    expect(hiddenCards.length).toBe(0);
    expect(container.textContent).toContain("Timeline Track 1");
    expect(container.textContent).toContain("Timeline Track 2");
  });

  test("renders timeline tracks regardless of can_make_assumptions", () => {
    mockGameContext.snapshot.permissions.can_make_assumptions = false;

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    expect(container.textContent).toContain("Timeline Track 1");
    expect(container.textContent).toContain("Timeline Track 2");
    expect(container.textContent).toContain("Artist 1");
    expect(container.textContent).toContain("Artist 2");
  });

  test("handles missing track gracefully", () => {
    mockGameContext.snapshot.game.track = null;
    mockGameContext.snapshot.permissions.can_make_assumptions = true;

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    expect(container.textContent).toContain("Timeline Track 1");
    expect(container.textContent).toContain("Timeline Track 2");

    const hiddenCards = container.querySelectorAll(
      '[aria-label="Hidden track card"][aria-hidden="false"]',
    );
    expect(hiddenCards.length).toBe(0);
  });

  test("shows assumption card with user avatar in placeholder slot", () => {
    mockGameContext.snapshot.permissions.can_make_assumptions = true;
    mockGameContext.snapshot.game.turn.assumptions = {
      "0": "current-user-123",
    };

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    const avatars = container.querySelectorAll('img[src="https://example.com/avatar.jpg"]');
    expect(avatars.length).toBeGreaterThan(0);
  });

  describe("scroll snaps only to slots and own assumption", () => {
    const scopeUser = {
      uuid: "current-user-123",
      name: "Test User",
    };

    test("slots have data-snap", () => {
      mockGameContext.snapshot.permissions.can_make_assumptions = true;
      mockGameContext.snapshot.game.turn.assumptions = {};
      currentUser.set(scopeUser);
      vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

      const { container } = render(Timeline);

      const snaps = container.querySelectorAll("[data-snap]");
      const slots = container.querySelectorAll("[data-position]:not(:has(img))");

      expect(snaps.length).toBe(3);
      expect(slots.length).toBe(3);

      slots.forEach((slot) => {
        expect(slot.hasAttribute("data-snap")).toBe(true);
      });
    });

    test("own assumption has data-snap", async () => {
      mockGameContext.snapshot.permissions.can_make_assumptions = true;
      mockGameContext.snapshot.game.turn.assumptions = {
        "0": "current-user-123",
      };
      currentUser.set(scopeUser);
      vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

      const screen = render(Timeline);

      await expect
        .element(screen.getByLabelText("Test User's assumption"))
        .toHaveAttribute("data-snap");
    });

    test("other user assumption does not have data-snap", async () => {
      mockGameContext.snapshot.permissions.can_make_assumptions = true;
      mockGameContext.snapshot.game.turn.assumptions = {
        "0": "user-1",
      };
      currentUser.set(scopeUser);
      vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

      const screen = render(Timeline);

      await expect
        .element(screen.getByLabelText("User 1's assumption"))
        .not.toHaveAttribute("data-snap");
    });

    test("track cells do not have data-snap", () => {
      mockGameContext.snapshot.permissions.can_make_assumptions = true;
      mockGameContext.snapshot.game.turn.assumptions = {};
      currentUser.set(scopeUser);
      vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

      const { container } = render(Timeline);

      const allCells = container.querySelectorAll("[role='listitem']");
      const tracksWithSnap = Array.from(allCells).filter(
        (el) => !el.hasAttribute("data-position") && el.hasAttribute("data-snap"),
      );

      expect(tracksWithSnap.length).toBe(0);
    });

    test("mixed: only slots and own assumption get data-snap", () => {
      mockGameContext.snapshot.permissions.can_make_assumptions = true;
      mockGameContext.snapshot.game.turn.assumptions = {
        "0": "user-1",
        "2": "current-user-123",
      };
      currentUser.set(scopeUser);
      vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

      const { container } = render(Timeline);

      const snaps = container.querySelectorAll("[data-snap]");
      const snapPositions = Array.from(snaps).map(
        (el) => el.dataset.position,
      );

      expect(snapPositions).toContain("2");
      expect(snapPositions).toContain("3");
      expect(snapPositions).not.toContain("0");
    });
  });

  test("slot positions shift when assumptions exist", () => {
    mockGameContext.snapshot.permissions.can_make_assumptions = true;
    mockGameContext.snapshot.game.turn.assumptions = {
      "0": "current-user-123",
    };

    vi.mocked(getGameContext).mockReturnValue(writable(mockGameContext));

    const { container } = render(Timeline);

    const slots = container.querySelectorAll('[data-position]');
    const positions = Array.from(slots).map((slot) => Number(slot.dataset.position));

    expect(slots.length).toBe(3);
    expect(positions[0]).toBe(0);
    expect(positions[1]).toBe(1);
    expect(positions[2]).toBe(2);
  });
});
