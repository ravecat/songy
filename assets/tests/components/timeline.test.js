import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { currentUser } from "~/stores/scope";
import GameContextFixture from "../fixtures/game_context_fixture.svelte";

import Timeline from "~components/timeline.svelte";

vi.mock("~/stores/scope", async () => {
  const { writable } = await import("svelte/store");

  return {
    currentUser: writable(null),
    provider: writable(undefined),
  };
});

describe("Timeline", () => {
  let mockGameContext;

  function renderWithSession(session = mockGameContext) {
    return render(GameContextFixture, {
      component: Timeline,
      session,
    });
  }

  beforeEach(() => {
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

    const { container } = renderWithSession();

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBeGreaterThanOrEqual(1);
  });

  test("hides track card when can_make_assumptions is false", () => {
    mockGameContext.snapshot.permissions.can_make_assumptions = false;

    const { container } = renderWithSession();

    const timelineTrack1 = screen.getAllByText("Timeline Track 1");
    const timelineTrack2 = screen.getAllByText("Timeline Track 2");

    expect(timelineTrack1.length).toBeGreaterThan(0);
    expect(timelineTrack2.length).toBeGreaterThan(0);

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(0);
  });

  test("hides track card when permissions is undefined", () => {
    mockGameContext.snapshot.permissions = undefined;

    const { container } = renderWithSession();

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(0);
  });

  test("hides track card when permissions is null", () => {
    mockGameContext.snapshot.permissions = null;

    const { container } = renderWithSession();

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(0);
  });

  test("player in ready phase sees track card", () => {
    mockGameContext.snapshot.game.turn.phase = "ready";
    mockGameContext.snapshot.permissions.can_make_assumptions = true;
    mockGameContext.snapshot.game.turn.assumptions = {
      "1": "current-user-123",
    };

    const { container } = renderWithSession();

    // Should show 1 hidden card: assumption slot with user avatar
    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
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

    const { container } = renderWithSession();

    // Should show 1 hidden card: assumption slot with user avatar
    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(1);
  });

  test("no one sees track card in results phase", () => {
    mockGameContext.snapshot.game.turn.phase = "results";
    mockGameContext.snapshot.permissions.can_make_assumptions = false;
    mockGameContext.snapshot.permissions.can_see_assumptions = true;

    const { container } = renderWithSession();

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(0);

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);
  });

  test("renders timeline tracks regardless of can_make_assumptions", () => {
    mockGameContext.snapshot.permissions.can_make_assumptions = false;

    renderWithSession();

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Artist 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Artist 2").length).toBeGreaterThan(0);
  });

  test("handles missing track gracefully", () => {
    mockGameContext.snapshot.game.track = null;
    mockGameContext.snapshot.permissions.can_make_assumptions = true;

    const { container } = renderWithSession();

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(0);
  });

  test("shows assumption card with user avatar in placeholder slot", () => {
    mockGameContext.snapshot.permissions.can_make_assumptions = true;
    mockGameContext.snapshot.game.turn.assumptions = {
      "0": "current-user-123",
    };

    const { container } = renderWithSession();

    const avatars = container.querySelectorAll('img[src="https://example.com/avatar.jpg"]');
    expect(avatars.length).toBeGreaterThan(0);
  });

  describe("scroll snaps only to slots and own assumption", () => {
    function renderTimeline(assumptions, scopeUser) {
      mockGameContext.snapshot.permissions.can_make_assumptions = true;
      mockGameContext.snapshot.game.turn.assumptions = assumptions;
      currentUser.set(scopeUser);

      return renderWithSession();
    }

    const scopeUser = {
      uuid: "current-user-123",
      name: "Test User",
    };

    const otherUser = {
      uuid: "user-1",
      name: "User 1",
    };

    test("slots have data-snap", () => {
      const { container } = renderTimeline({}, scopeUser);

      // Timeline: [A, B] -> slot(0) - A - slot(1) - B - slot(2)
      const snaps = container.querySelectorAll("[data-snap]");
      const slots = container.querySelectorAll("[data-position]:not(:has(img))");

      expect(snaps.length).toBe(3);
      expect(slots.length).toBe(3);

      slots.forEach((slot) => {
        expect(slot).toHaveAttribute("data-snap");
      });
    });

    test("own assumption has data-snap", () => {
      renderTimeline(
        { "0": "current-user-123" },
        scopeUser,
      );

      // assumption(0) - A - slot(1) - B - slot(2)
      const ownAssumption = screen.getByLabelText("Test User's assumption");
      expect(ownAssumption).toHaveAttribute("data-snap");
    });

    test("other user assumption does not have data-snap", () => {
      renderTimeline(
        { "0": "user-1" },
        scopeUser,
      );

      // assumption(0)[user-1] - A - slot(2) - B - slot(3)
      const otherAssumption = screen.getByLabelText("User 1's assumption");
      expect(otherAssumption).not.toHaveAttribute("data-snap");
    });

    test("track cells do not have data-snap", () => {
      const { container } = renderTimeline({}, scopeUser);

      const allCells = container.querySelectorAll("[role='listitem']");
      const tracksWithSnap = Array.from(allCells).filter(
        (el) => !el.hasAttribute("data-position") && el.hasAttribute("data-snap"),
      );

      expect(tracksWithSnap.length).toBe(0);
    });

    test("mixed: only slots and own assumption get data-snap", () => {
      const { container } = renderTimeline(
        { "0": "user-1", "2": "current-user-123" },
        scopeUser,
      );

      // other(0) - A - own(2) - B - slot(3)
      const snaps = container.querySelectorAll("[data-snap]");
      const snapPositions = Array.from(snaps).map(
        (el) => el.dataset.position,
      );

      // own assumption at 2, slot at 3
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

    const { container } = renderWithSession();

    // Timeline: [A, B] (2 tracks)
    // With assumption at position 0:
    // assumption(0) - track A - slot(1) - track B - slot(2)
    // Positions: slots and assumptions have data-position, tracks don't
    const slots = container.querySelectorAll('[data-position]');
    const positions = Array.from(slots).map(s => Number(s.dataset.position));

    // Should have 3 elements with data-position (assumption + 2 slots)
    expect(slots.length).toBe(3);
    // Assumption at position 0
    expect(positions[0]).toBe(0);
    // First slot after track A: position 1
    expect(positions[1]).toBe(1);
    // Second slot after track B: position 2
    expect(positions[2]).toBe(2);
  });
});
