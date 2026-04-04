import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import GameContextFixture from "../fixtures/game_context_fixture.svelte";

import Player from "~components/player.svelte";

describe("Player", () => {
  let mockChannelContext;
  const ownerUser = { uuid: "user-1", name: "Alice" };
  const playerUser = { uuid: "user-2", name: "Bob" };

  const renderForUser = (_user) => {
    render(GameContextFixture, {
      component: Player,
      session: mockChannelContext,
    });
  };

  beforeEach(() => {
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
      startGame: vi.fn(),
      advanceTurn: vi.fn(),
      startPlayback: vi.fn(),
      pausePlayback: vi.fn(),
    };
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("slot layout", () => {
    test("renders player controls group", () => {
      renderForUser(ownerUser);

      expect(
        screen.getByRole("group", { name: "Player controls" }),
      ).toBeInTheDocument();
    });

    test("always renders play button in center slot", () => {
      renderForUser(ownerUser);

      expect(
        screen.getByRole("button", { name: "Play track" }),
      ).toBeInTheDocument();
    });
  });

  describe("waiting game | none turn", () => {
    beforeEach(() => {
      mockChannelContext.snapshot.game.status = "waiting";
      mockChannelContext.snapshot.game.turn = null;
    });

    describe("owner", () => {
      test("shows start game button in right slot", () => {
        mockChannelContext.snapshot.permissions.can_start_game = true;

        renderForUser(ownerUser);

        const startButton = screen.getByRole("button", { name: "Start game" });
        expect(startButton).toBeEnabled();
      });

      test("disables play button", () => {
        renderForUser(ownerUser);

        const playButton = screen.getByRole("button", {
          name: "Play track",
        });
        expect(playButton).toBeDisabled();
      });

      test("starts game when start is clicked", async () => {
        mockChannelContext.snapshot.permissions.can_start_game = true;

        renderForUser(ownerUser);

        await fireEvent.click(
          screen.getByRole("button", { name: "Start game" }),
        );

        expect(mockChannelContext.startGame).toHaveBeenCalled();
      });
    });

    describe("challenger", () => {
      test("shows disabled forward button in right slot", () => {
        renderForUser(playerUser);

        expect(
          screen.getByRole("button", { name: "Forward" }),
        ).toBeDisabled();
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

        renderForUser(ownerUser);

        await fireEvent.click(screen.getByRole("button", { name: "Ready" }));

        expect(mockChannelContext.advanceTurn).toHaveBeenCalled();
      });

      test("disables play button during waiting phase", () => {
        mockChannelContext.snapshot.permissions.can_control_playback = false;

        renderForUser(ownerUser);

        const playButton = screen.getByRole("button", {
          name: "Play track",
        });
        expect(playButton).toBeDisabled();
      });
    });

    describe("player", () => {
      beforeEach(() => {
        mockChannelContext.snapshot.game.cursor = 1;
      });

      test("disables play button during waiting phase", () => {
        mockChannelContext.snapshot.permissions.can_control_playback = false;

        renderForUser(playerUser);

        const playButton = screen.getByRole("button", {
          name: "Play track",
        });
        expect(playButton).toBeDisabled();
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
      test("shows disabled forward button without advance permission", () => {
        mockChannelContext.snapshot.permissions.can_control_playback = true;

        renderForUser(ownerUser);

        expect(
          screen.getByRole("button", { name: "Play track" }),
        ).toBeEnabled();
        expect(
          screen.getByRole("button", { name: "Forward" }),
        ).toBeDisabled();
      });
    });

    describe("player", () => {
      beforeEach(() => {
        mockChannelContext.snapshot.game.cursor = 1;
      });

      test("shows disabled forward button without advance permission", () => {
        mockChannelContext.snapshot.permissions.can_control_playback = true;
        mockChannelContext.snapshot.permissions.can_advance_turn = false;

        renderForUser(playerUser);

        expect(
          screen.getByRole("button", { name: "Play track" }),
        ).toBeEnabled();
        expect(
          screen.getByRole("button", { name: "Forward" }),
        ).toBeDisabled();
      });

      test("shows enabled forward button with advance permission", () => {
        mockChannelContext.snapshot.permissions.can_control_playback = true;
        mockChannelContext.snapshot.permissions.can_advance_turn = true;

        renderForUser(playerUser);

        expect(
          screen.getByRole("button", { name: "Play track" }),
        ).toBeEnabled();
        expect(
          screen.getByRole("button", { name: "Forward" }),
        ).toBeEnabled();
      });
    });

    describe("challenger", () => {
      test("shows disabled forward button without advance permission", () => {
        mockChannelContext.snapshot.permissions.can_control_playback = false;
        mockChannelContext.snapshot.permissions.can_advance_turn = false;

        renderForUser(playerUser);

        expect(
          screen.getByRole("button", { name: "Play track" }),
        ).toBeDisabled();
        expect(
          screen.getByRole("button", { name: "Forward" }),
        ).toBeDisabled();
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

    test("shows play again button in left slot", () => {
      renderForUser(ownerUser);

      expect(
        screen.getByRole("button", { name: "Play again" }),
      ).toBeEnabled();
    });

    test("shows disabled forward button in right slot", () => {
      renderForUser(ownerUser);

      expect(
        screen.getByRole("button", { name: "Forward" }),
      ).toBeDisabled();
    });

    test("enables play button", () => {
      renderForUser(ownerUser);

      expect(
        screen.getByRole("button", { name: "Play track" }),
      ).toBeEnabled();
    });
  });

  describe("play button aria-pressed", () => {
    test("sets aria-pressed=false when not playing", () => {
      mockChannelContext.snapshot.game.player.is_playback = false;

      renderForUser(ownerUser);

      expect(
        screen.getByRole("button", { name: "Play track" }),
      ).toHaveAttribute("aria-pressed", "false");
    });

    test("sets aria-pressed=true when playing", () => {
      mockChannelContext.snapshot.game.player.is_playback = true;
      mockChannelContext.snapshot.permissions.can_control_playback = true;

      renderForUser(ownerUser);

      expect(
        screen.getByRole("button", { name: "Pause track" }),
      ).toHaveAttribute("aria-pressed", "true");
    });
  });

  describe("playback events", () => {
    test("pushes start_playback when paused", async () => {
      mockChannelContext.snapshot.game.player.is_playback = false;
      mockChannelContext.snapshot.permissions.can_control_playback = true;

      renderForUser(ownerUser);

      await fireEvent.click(screen.getByRole("button", { name: "Play track" }));

      expect(mockChannelContext.startPlayback).toHaveBeenCalled();
    });

    test("pushes pause_playback when playing", async () => {
      mockChannelContext.snapshot.game.player.is_playback = true;
      mockChannelContext.snapshot.permissions.can_control_playback = true;

      renderForUser(ownerUser);

      await fireEvent.click(
        screen.getByRole("button", { name: "Pause track" }),
      );

      expect(mockChannelContext.pausePlayback).toHaveBeenCalled();
    });
  });
});
