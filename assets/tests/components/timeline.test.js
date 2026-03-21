import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import * as GameContext from "~components/game_channel.svelte";
import * as ScopeContext from "~components/scope.svelte";

import Timeline from "~components/timeline.svelte";

describe("Timeline", () => {
  let mockGameContext;

  beforeEach(() => {
    mockGameContext = {
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
          phase: TURN_PHASE.READY,
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
    };
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("shows track card when can_make_assumptions is true", () => {
    mockGameContext.permissions.can_make_assumptions = true;
    mockGameContext.game.turn.assumptions = {
      "1": "current-user-123",
    };
    mockGameContext.game.timelines["current-user-123"] = [
      mockGameContext.game.timelines["current-user-123"][0],
      mockGameContext.game.track,
      mockGameContext.game.timelines["current-user-123"][1],
    ];

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    const { container } = render(Timeline);

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBeGreaterThanOrEqual(1);
  });

  test("hides track card when can_make_assumptions is false", () => {
    mockGameContext.permissions.can_make_assumptions = false;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    const { container } = render(Timeline);

    const timelineTrack1 = screen.getAllByText("Timeline Track 1");
    const timelineTrack2 = screen.getAllByText("Timeline Track 2");

    expect(timelineTrack1.length).toBeGreaterThan(0);
    expect(timelineTrack2.length).toBeGreaterThan(0);

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(0);
  });

  test("hides track card when permissions is undefined", () => {
    mockGameContext.permissions = undefined;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    const { container } = render(Timeline);

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(0);
  });

  test("hides track card when permissions is null", () => {
    mockGameContext.permissions = null;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    const { container } = render(Timeline);

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(0);
  });

  test("player in ready phase sees track card", () => {
    mockGameContext.game.turn.phase = TURN_PHASE.READY;
    mockGameContext.permissions.can_make_assumptions = true;
    mockGameContext.game.turn.assumptions = {
      "1": "current-user-123",
    };

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    const { container } = render(Timeline);

    // Should show 1 hidden card: assumption slot with user avatar
    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(1);
  });

  test("challenger in challenging phase sees track card", () => {
    mockGameContext.game.turn.phase = TURN_PHASE.CHALLENGING;
    mockGameContext.permissions.can_make_assumptions = true;
    mockGameContext.game.queue = ["user-1", "current-user-123"];
    mockGameContext.game.cursor = 0;
    mockGameContext.game.turn.assumptions = {
      "1": "current-user-123",
    };
    mockGameContext.game.timelines["user-1"] = [
      mockGameContext.game.timelines["current-user-123"][0],
      mockGameContext.game.timelines["current-user-123"][1],
    ];

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    const { container } = render(Timeline);

    // Should show 1 hidden card: assumption slot with user avatar
    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(1);
  });

  test("no one sees track card in results phase", () => {
    mockGameContext.game.turn.phase = TURN_PHASE.RESULTS;
    mockGameContext.permissions.can_make_assumptions = false;
    mockGameContext.permissions.can_see_assumptions = true;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    const { container } = render(Timeline);

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(0);

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);
  });

  test("renders timeline tracks regardless of can_make_assumptions", () => {
    mockGameContext.permissions.can_make_assumptions = false;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    render(Timeline);

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Artist 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Artist 2").length).toBeGreaterThan(0);
  });

  test("handles missing track gracefully", () => {
    mockGameContext.game.track = null;
    mockGameContext.permissions.can_make_assumptions = true;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    render(Timeline);

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);

    const { container } = render(Timeline);
    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"][aria-hidden="false"]');
    expect(hiddenCards.length).toBe(0);
  });

  test("shows assumption card with user avatar in placeholder slot", () => {
    mockGameContext.permissions.can_make_assumptions = true;
    mockGameContext.game.turn.assumptions = {
      "0": "current-user-123",
    };

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    const { container } = render(Timeline);

    const avatars = container.querySelectorAll('img[src="https://example.com/avatar.jpg"]');
    expect(avatars.length).toBeGreaterThan(0);
  });

  describe("scroll snaps only to slots and own assumption", () => {
    function renderTimeline(assumptions, scopeUser) {
      mockGameContext.permissions.can_make_assumptions = true;
      mockGameContext.game.turn.assumptions = assumptions;

      vi.spyOn(GameContext, "getGameContext").mockReturnValue(mockGameContext);
      vi.spyOn(ScopeContext, "getScopeContext").mockReturnValue({
        user: scopeUser,
      });

      return render(Timeline);
    }

    const currentUser = {
      uuid: "current-user-123",
      name: "Test User",
    };

    const otherUser = {
      uuid: "user-1",
      name: "User 1",
    };

    test("slots have data-snap", () => {
      const { container } = renderTimeline({}, currentUser);

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
        currentUser,
      );

      // assumption(0) - A - slot(1) - B - slot(2)
      const ownAssumption = screen.getByLabelText("Test User's assumption");
      expect(ownAssumption).toHaveAttribute("data-snap");
    });

    test("other user assumption does not have data-snap", () => {
      renderTimeline(
        { "0": "user-1" },
        currentUser,
      );

      // assumption(0)[user-1] - A - slot(2) - B - slot(3)
      const otherAssumption = screen.getByLabelText("User 1's assumption");
      expect(otherAssumption).not.toHaveAttribute("data-snap");
    });

    test("track cells do not have data-snap", () => {
      const { container } = renderTimeline({}, currentUser);

      const allCells = container.querySelectorAll("[role='listitem']");
      const tracksWithSnap = Array.from(allCells).filter(
        (el) => !el.hasAttribute("data-position") && el.hasAttribute("data-snap"),
      );

      expect(tracksWithSnap.length).toBe(0);
    });

    test("mixed: only slots and own assumption get data-snap", () => {
      const { container } = renderTimeline(
        { "0": "user-1", "2": "current-user-123" },
        currentUser,
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
    mockGameContext.permissions.can_make_assumptions = true;
    mockGameContext.game.turn.assumptions = {
      "0": "current-user-123",
    };

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const getScopeContextSpy = vi.spyOn(ScopeContext, "getScopeContext");
    getScopeContextSpy.mockReturnValue({
      user: {
        uuid: "current-user-123",
        name: "Test User",
      },
    });

    const { container } = render(Timeline);

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
