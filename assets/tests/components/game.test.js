import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import * as GameContext from "~/contexts/game";
import { currentUser } from "~/stores/scope";

import Game from "~components/game.svelte";

vi.mock("~/stores/scope", async () => {
  const { writable } = await import("svelte/store");

  return {
    currentUser: writable(null),
    provider: writable(undefined),
  };
});

describe("Game", () => {
  let mockChannelContext;
  let getGameContextSpy;

  beforeEach(() => {
    currentUser.set({
      uuid: "user-1",
      name: "Alice",
    });

    mockChannelContext = {
      snapshot: {
        game: {
          participants: {
            "user-1": {
              uuid: "user-1",
              name: "Alice",
              avatar_url: "https://example.com/alice.jpg",
            },
            "user-2": {
              uuid: "user-2",
              name: "Bob",
              avatar_url: "https://example.com/bob.jpg",
            },
          },
          queue: ["user-1", "user-2"],
          cursor: 0,
          track: null,
          timelines: {
            "user-1": [
              {
                id: "timeline-track",
                title: "Timeline Track",
                artist: "Timeline Artist",
                year: 2019,
                cover_url: null,
                meta: {},
              },
            ],
            "user-2": [
              {
                id: "timeline-track",
                title: "Timeline Track",
                artist: "Timeline Artist",
                year: 2019,
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
          can_start_turn: false,
          can_control_playback: false,
          can_advance_turn: false,
          can_start_game: false,
          can_restart_game: false,
          can_see_assumptions: false,
          can_make_assumptions: false,
        },
        timer: null,
      },
    };
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders timeline details for active player in ready phase", () => {
    mockChannelContext.snapshot.game.turn.phase = "ready";

    currentUser.set({ uuid: "user-1", name: "Alice" });
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.getAllByText("Timeline Track")).toHaveLength(2);
    expect(screen.getAllByText("Timeline Artist")).toHaveLength(2);
    expect(screen.getByText("2019")).toBeInTheDocument();
  });

  test("renders timeline details for passive player in ready phase", () => {
    mockChannelContext.snapshot.game.turn.phase = "ready";

    currentUser.set({ uuid: "user-2", name: "Bob" });
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.getAllByText("Timeline Track")).toHaveLength(2);
    expect(screen.getAllByText("Timeline Artist")).toHaveLength(2);
    expect(screen.getByText("2019")).toBeInTheDocument();
  });

  test("displays waiting view on waiting phase", () => {
    mockChannelContext.snapshot.game.turn.phase = "waiting";
    mockChannelContext.snapshot.permissions.can_start_turn = true;

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.getByText("It's your turn")).toBeInTheDocument();
  });

  test("displays waiting view for passive player", () => {
    mockChannelContext.snapshot.game.turn.phase = "waiting";

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.getByText("Alice turn")).toBeInTheDocument();
  });

  test("displays results view on results phase", () => {
    mockChannelContext.snapshot.game.turn.phase = "results";
    mockChannelContext.snapshot.game.track = {
      id: "track-1",
      title: "Test Track",
      artist: "Test Artist",
      year: 2020,
      cover_url: "https://example.com/cover.jpg",
      meta: {
        preview_url: "https://example.com/preview.mp3",
      },
    };

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.getByText("Test Artist")).toBeInTheDocument();
    expect(screen.getByText("Test Track")).toBeInTheDocument();
    expect(screen.getByText("2020")).toBeInTheDocument();
  });

  test("renders nothing when turn phase is undefined", () => {
    mockChannelContext.snapshot.game.turn = undefined;

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  test("renders nothing when state is undefined", () => {
    mockChannelContext.snapshot.game = {
      participants: {},
      turn: undefined,
    };

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.queryByText("waiting")).not.toBeInTheDocument();
    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  test("renders nothing when turn phase is null", () => {
    mockChannelContext.snapshot.game.turn.phase = null;

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Game);

    expect(screen.queryByText("Alice")).not.toBeInTheDocument();
  });

  test("throws error when gameContext is missing", () => {
    getGameContextSpy.mockImplementation(() => {
      throw new Error("getGameContext() must be called within a game context");
    });

    expect(() => {
      render(Game);
    }).toThrow("getGameContext() must be called within a game context");
  });

  test.each(["turn_countdown", "", "unknown_phase", 123, {}, []])(
    "renders nothing for invalid phase: %s",
    (phase) => {
      mockChannelContext.snapshot.game.turn.phase = phase;

      getGameContextSpy.mockReturnValue(mockChannelContext);

      render(Game);

      expect(screen.queryByText("Alice")).not.toBeInTheDocument();
    }
  );
});
