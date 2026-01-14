import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import * as GameContext from "~components/GameChannel.svelte";

import Timeline from "~components/Timeline.svelte";

describe("Timeline - Track Card Visibility", () => {
  let mockGameContext;

  beforeEach(() => {
    mockGameContext = {
      game: {
        track: {
          id: "track-123",
          title: "Current Track",
          artist: "Current Artist",
          year: 2024,
        },
        turn: {
          phase: TURN_PHASE.READY,
          timeline: [
            {
              id: "timeline-1",
              title: "Timeline Track 1",
              artist: "Artist 1",
              year: 2020,
            },
            {
              id: "timeline-2",
              title: "Timeline Track 2",
              artist: "Artist 2",
              year: 2021,
            },
          ],
          assumptions: [
            {
              id: "assumption-1",
              user_id: "user-1",
              track_id: "timeline-1",
            },
          ],
        },
      },
      permissions: {
        can_control_playback: true,
        can_advance_turn: true,
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

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(Timeline);

    const hiddenCards = container.querySelectorAll('[aria-label="Hidden track card"]');
    expect(hiddenCards.length).toBeGreaterThanOrEqual(1);
  });

  test("hides track card when can_make_assumptions is false", () => {
    mockGameContext.permissions.can_make_assumptions = false;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(Timeline);

    const timelineTrack1 = screen.getAllByText("Timeline Track 1");
    const timelineTrack2 = screen.getAllByText("Timeline Track 2");

    expect(timelineTrack1.length).toBeGreaterThan(0);
    expect(timelineTrack2.length).toBeGreaterThan(0);

    const allCards = container.querySelectorAll('.wrapper');
    const cardsInTimeline = mockGameContext.game.turn.timeline.length;

    expect(allCards.length).toBe(cardsInTimeline);
  });

  test("hides track card when permissions is undefined", () => {
    mockGameContext.permissions = undefined;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(Timeline);

    const allCards = container.querySelectorAll('.wrapper');
    const cardsInTimeline = mockGameContext.game.turn.timeline.length;
    expect(allCards.length).toBe(cardsInTimeline);
  });

  test("hides track card when permissions is null", () => {
    mockGameContext.permissions = null;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(Timeline);

    const allCards = container.querySelectorAll('.wrapper');
    const cardsInTimeline = mockGameContext.game.turn.timeline.length;
    expect(allCards.length).toBe(cardsInTimeline);
  });

  test("player in ready phase sees track card", () => {
    mockGameContext.game.turn.phase = TURN_PHASE.READY;
    mockGameContext.permissions.can_make_assumptions = true;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(Timeline);

    const allCards = container.querySelectorAll('.wrapper');
    const cardsInTimeline = mockGameContext.game.turn.timeline.length;

    expect(allCards.length).toBe(cardsInTimeline + 1);
  });

  test("challenger in challenging phase sees track card", () => {
    mockGameContext.game.turn.phase = TURN_PHASE.CHALLENGING;
    mockGameContext.permissions.can_make_assumptions = true;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(Timeline);

    const allCards = container.querySelectorAll('.wrapper');
    const cardsInTimeline = mockGameContext.game.turn.timeline.length;

    expect(allCards.length).toBe(cardsInTimeline + 1);
  });

  test("no one sees track card in results phase", () => {
    mockGameContext.game.turn.phase = TURN_PHASE.RESULTS;
    mockGameContext.permissions.can_make_assumptions = false;
    mockGameContext.permissions.can_see_assumptions = true;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(Timeline);

    const allCards = container.querySelectorAll('.wrapper');
    const cardsInTimeline = mockGameContext.game.turn.timeline.length;
    expect(allCards.length).toBe(cardsInTimeline);
  });

  test("renders timeline tracks regardless of can_make_assumptions", () => {
    mockGameContext.permissions.can_make_assumptions = false;

    const getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getGameContextSpy.mockReturnValue(mockGameContext);

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

    const { container } = render(Timeline);

    expect(screen.getAllByText("Timeline Track 1").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track 2").length).toBeGreaterThan(0);

    const allCards = container.querySelectorAll('.wrapper');
    expect(allCards.length).toBeGreaterThan(0);
  });
});
