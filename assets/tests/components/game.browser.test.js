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

import Game from "~components/game.svelte";
import { getGameContext } from "~/contexts/game";

describe("Game", () => {
  let mockChannelContext;

  beforeEach(() => {
    vi.clearAllMocks();

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
      status: "ready",
      error: null,
    };
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders timeline details for active player in ready phase", async () => {
    mockChannelContext.snapshot.game.turn.phase = "ready";

    currentUser.set({ uuid: "user-1", name: "Alice" });
    vi.mocked(getGameContext).mockReturnValue(writable(mockChannelContext));

    const screen = render(Game);

    expect(screen.container.textContent).toContain("Timeline Track");
    expect(screen.container.textContent).toContain("Timeline Artist");
    await expect.element(screen.getByText("2019")).toBeVisible();
  });

  test("renders timeline details for passive player in ready phase", async () => {
    mockChannelContext.snapshot.game.turn.phase = "ready";

    currentUser.set({ uuid: "user-2", name: "Bob" });
    vi.mocked(getGameContext).mockReturnValue(writable(mockChannelContext));

    const screen = render(Game);

    expect(screen.container.textContent).toContain("Timeline Track");
    expect(screen.container.textContent).toContain("Timeline Artist");
    await expect.element(screen.getByText("2019")).toBeVisible();
  });

  test("displays waiting view on waiting phase", async () => {
    mockChannelContext.snapshot.game.turn.phase = "waiting";
    mockChannelContext.snapshot.permissions.can_start_turn = true;

    vi.mocked(getGameContext).mockReturnValue(writable(mockChannelContext));

    const screen = render(Game);

    await expect.element(screen.getByText("It's your turn")).toBeVisible();
  });

  test("displays waiting view for passive player", async () => {
    mockChannelContext.snapshot.game.turn.phase = "waiting";

    vi.mocked(getGameContext).mockReturnValue(writable(mockChannelContext));

    const screen = render(Game);

    await expect.element(screen.getByText("Alice turn")).toBeVisible();
  });

  test("displays results view on results phase", async () => {
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

    vi.mocked(getGameContext).mockReturnValue(writable(mockChannelContext));

    const screen = render(Game);

    await expect.element(screen.getByText("Test Artist")).toBeVisible();
    await expect.element(screen.getByText("Test Track")).toBeVisible();
    await expect.element(screen.getByText("2020")).toBeVisible();
  });

  test("displays finished view on finished status even with stale results phase", async () => {
    mockChannelContext.snapshot.game.status = "finished";
    mockChannelContext.snapshot.game.scores = {
      "user-1": 10,
      "user-2": 7,
    };
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

    vi.mocked(getGameContext).mockReturnValue(writable(mockChannelContext));

    const screen = render(Game);

    await expect
      .element(screen.getByRole("heading", { name: "Alice wins" }))
      .toBeVisible();
    await expect
      .element(screen.getByRole("list", { name: "Final leaderboard" }))
      .toBeVisible();
    await expect.element(screen.getByText("Test Artist")).not.toBeInTheDocument();
  });

  test("renders nothing when turn phase is undefined", () => {
    mockChannelContext.snapshot.game.turn = undefined;

    vi.mocked(getGameContext).mockReturnValue(writable(mockChannelContext));

    const screen = render(Game);

    expect(screen.container.textContent).not.toContain("Alice");
  });

  test("renders nothing when state is undefined", () => {
    mockChannelContext.snapshot.game = {
      participants: {},
      turn: undefined,
    };

    vi.mocked(getGameContext).mockReturnValue(writable(mockChannelContext));

    const screen = render(Game);

    expect(screen.container.textContent).not.toContain("waiting");
    expect(screen.container.textContent).not.toContain("Alice");
  });

  test("renders nothing when turn phase is null", () => {
    mockChannelContext.snapshot.game.turn.phase = null;

    vi.mocked(getGameContext).mockReturnValue(writable(mockChannelContext));

    const screen = render(Game);

    expect(screen.container.textContent).not.toContain("Alice");
  });

  test("throws error when gameContext is missing", () => {
    vi.mocked(getGameContext).mockImplementation(() => {
      throw new Error("missing game context");
    });

    expect(() => {
      render(Game);
    }).toThrow();
  });

  test.each(["turn_countdown", "", "unknown_phase", 123, {}, []])(
    "renders nothing for invalid phase: %s",
    (phase) => {
      mockChannelContext.snapshot.game.turn.phase = phase;

      vi.mocked(getGameContext).mockReturnValue(writable(mockChannelContext));

      const screen = render(Game);

      expect(screen.container.textContent).not.toContain("Alice");
    },
  );
});
