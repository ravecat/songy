import { writable } from "svelte/store";
import { render } from "vitest-browser-svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";

vi.mock("~/contexts/game");

vi.mock(import("@inertiajs/svelte"), async (importOriginal) => {
  const actual = await importOriginal();

  return {
    ...actual,
    inertia: () => ({
      destroy() {},
    }),
  };
});

import Player from "~components/player.svelte";
import { getGameContext } from "~/contexts/game";

describe("Player", () => {
  let mockChannelContext;
  let mockSession;

  beforeEach(() => {
    vi.clearAllMocks();

    mockChannelContext = {
      snapshot: {
        game: {
          owner_id: "user-1",
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
          status: "waiting",
          turn: null,
          player: {
            is_playback: false,
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
        timer: null,
      },
      status: "ready",
      error: null,
    };

    const sessionStore = writable(mockChannelContext);

    mockSession = {
      subscribe: sessionStore.subscribe,
      startGame: vi.fn(),
      advanceTurn: vi.fn(),
      makeAssumption: vi.fn(),
      startPlayback: vi.fn(),
      pausePlayback: vi.fn(),
    };

    vi.mocked(getGameContext).mockReturnValue(mockSession);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("slot layout", () => {
    test("renders player controls group", async () => {
      const screen = render(Player);

      await expect
        .element(screen.getByRole("group", { name: "Player controls" }))
        .toBeVisible();
    });

    test("always renders play button in center slot", async () => {
      const screen = render(Player);

      await expect
        .element(screen.getByRole("button", { name: "Play track" }))
        .toBeVisible();
    });
  });

  describe("waiting game | none turn", () => {
    beforeEach(() => {
      mockChannelContext.snapshot.game.status = "waiting";
      mockChannelContext.snapshot.game.turn = null;
    });

    describe("owner", () => {
      test("shows start game button in right slot", async () => {
        mockChannelContext.snapshot.permissions.can_start_game = true;

        const screen = render(Player);

        await expect
          .element(screen.getByRole("button", { name: "Start game" }))
          .toBeEnabled();
      });

      test("disables play button", async () => {
        const screen = render(Player);

        await expect
          .element(screen.getByRole("button", { name: "Play track" }))
          .toBeDisabled();
      });

      test("starts game when start is clicked", async () => {
        mockChannelContext.snapshot.permissions.can_start_game = true;

        const screen = render(Player);

        await screen.getByRole("button", { name: "Start game" }).click();

        expect(mockSession.startGame).toHaveBeenCalled();
      });
    });

    describe("challenger", () => {
      test("shows disabled forward button in right slot", async () => {
        const screen = render(Player);

        await expect
          .element(screen.getByRole("button", { name: "Forward" }))
          .toBeDisabled();
      });
    });
  });

  describe("in progress game | waiting turn", () => {
    beforeEach(() => {
      mockChannelContext.snapshot.game.status = "in_progress";
      mockChannelContext.snapshot.game.turn = {
        phase: "waiting",
        assumptions: {},
        winner_id: null,
      };
    });

    describe("owner", () => {
      test("advances turn when ready is clicked", async () => {
        mockChannelContext.snapshot.permissions.can_start_turn = true;

        const screen = render(Player);

        await screen.getByRole("button", { name: "Ready" }).click();

        expect(mockSession.advanceTurn).toHaveBeenCalled();
      });

      test("disables play button during waiting phase", async () => {
        mockChannelContext.snapshot.permissions.can_control_playback = false;

        const screen = render(Player);

        await expect
          .element(screen.getByRole("button", { name: "Play track" }))
          .toBeDisabled();
      });
    });

    describe("player", () => {
      beforeEach(() => {
        mockChannelContext.snapshot.game.cursor = 1;
      });

      test("disables play button during waiting phase", async () => {
        mockChannelContext.snapshot.permissions.can_control_playback = false;

        const screen = render(Player);

        await expect
          .element(screen.getByRole("button", { name: "Play track" }))
          .toBeDisabled();
      });
    });
  });

  describe("in progress game | ready turn", () => {
    beforeEach(() => {
      mockChannelContext.snapshot.game.status = "in_progress";
      mockChannelContext.snapshot.game.turn = {
        phase: "ready",
        assumptions: {},
        winner_id: null,
      };
    });

    describe("owner", () => {
      test("shows disabled forward button without advance permission", async () => {
        mockChannelContext.snapshot.permissions.can_control_playback = true;

        const screen = render(Player);

        await expect
          .element(screen.getByRole("button", { name: "Play track" }))
          .toBeEnabled();
        await expect
          .element(screen.getByRole("button", { name: "Forward" }))
          .toBeDisabled();
      });
    });

    describe("player", () => {
      beforeEach(() => {
        mockChannelContext.snapshot.game.cursor = 1;
      });

      test("shows disabled forward button without advance permission", async () => {
        mockChannelContext.snapshot.permissions.can_control_playback = true;
        mockChannelContext.snapshot.permissions.can_advance_turn = false;

        const screen = render(Player);

        await expect
          .element(screen.getByRole("button", { name: "Play track" }))
          .toBeEnabled();
        await expect
          .element(screen.getByRole("button", { name: "Forward" }))
          .toBeDisabled();
      });
    });
  });

  describe("finished game", () => {
    beforeEach(() => {
      mockChannelContext.snapshot.game.status = "finished";
      mockChannelContext.snapshot.game.turn = null;
      mockChannelContext.snapshot.permissions.can_restart_game = true;
      mockChannelContext.snapshot.permissions.can_control_playback = true;
    });

    test("shows play again button in left slot", async () => {
      const screen = render(Player);

      await expect
        .element(screen.getByRole("button", { name: "Play again" }))
        .toBeEnabled();
    });

    test("shows disabled forward button in right slot", async () => {
      const screen = render(Player);

      await expect
        .element(screen.getByRole("button", { name: "Forward" }))
        .toBeDisabled();
    });

    test("enables play button", async () => {
      const screen = render(Player);

      await expect
        .element(screen.getByRole("button", { name: "Play track" }))
        .toBeEnabled();
    });
  });

  describe("play button aria-pressed", () => {
    test("sets aria-pressed=false when not playing", async () => {
      mockChannelContext.snapshot.game.player.is_playback = false;

      const screen = render(Player);

      await expect
        .element(screen.getByRole("button", { name: "Play track" }))
        .toHaveAttribute("aria-pressed", "false");
    });

    test("sets aria-pressed=true when playing", async () => {
      mockChannelContext.snapshot.game.player.is_playback = true;
      mockChannelContext.snapshot.permissions.can_control_playback = true;

      const screen = render(Player);

      await expect
        .element(screen.getByRole("button", { name: "Pause track" }))
        .toHaveAttribute("aria-pressed", "true");
    });
  });

  describe("playback events", () => {
    test("pushes start_playback when paused", async () => {
      mockChannelContext.snapshot.game.player.is_playback = false;
      mockChannelContext.snapshot.permissions.can_control_playback = true;

      const screen = render(Player);

      await screen.getByRole("button", { name: "Play track" }).click();

      expect(mockSession.startPlayback).toHaveBeenCalled();
    });

    test("pushes pause_playback when playing", async () => {
      mockChannelContext.snapshot.game.player.is_playback = true;
      mockChannelContext.snapshot.permissions.can_control_playback = true;

      const screen = render(Player);

      await screen.getByRole("button", { name: "Pause track" }).click();

      expect(mockSession.pausePlayback).toHaveBeenCalled();
    });
  });
});
