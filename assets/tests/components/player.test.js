import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { GAME_STATUS } from "~shared/types/game";
import { TURN_PHASE } from "~shared/types/turn";
import { PUSH_EVENT } from "~shared/types/channel";
import * as GameContext from "~components/game_channel.svelte";
import * as Scope from "~components/scope.svelte";

import Player from "~components/player.svelte";

describe("Player", () => {
  let mockChannelContext;
  let getScopeContextSpy;
  let getGameContextSpy;
  const ownerUser = { uuid: "user-1", name: "Alice" };
  const playerUser = { uuid: "user-2", name: "Bob" };

  const renderForUser = (user) => {
    getScopeContextSpy.mockReturnValue({ user });
    getGameContextSpy.mockReturnValue(mockChannelContext);
    render(Player);
  };

  beforeEach(() => {
    mockChannelContext = {
      game: {
        owner_id: "user-1",
        participants: [
          {
            uuid: "user-1",
            name: "Alice",
            avatar_url: "https://example.com/alice.jpg",
          },
          {
            uuid: "user-2",
            name: "Bob",
            avatar_url: "https://example.com/bob.jpg",
          },
        ],
        queue: ["user-1", "user-2"],
        cursor: 0,
        status: GAME_STATUS.WAITING,
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
      },
      channel: {
        push: vi.fn(),
      },
    };

    getScopeContextSpy = vi.spyOn(Scope, "getScopeContext");
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
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
      mockChannelContext.game.status = GAME_STATUS.WAITING;
      mockChannelContext.game.turn = null;
    });

    describe("owner", () => {
      test("shows start game button in right slot", () => {
        mockChannelContext.permissions.can_start_game = true;

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
        mockChannelContext.permissions.can_start_game = true;

        renderForUser(ownerUser);

        await fireEvent.click(
          screen.getByRole("button", { name: "Start game" }),
        );

        expect(mockChannelContext.channel.push).toHaveBeenCalledWith(
          PUSH_EVENT.START_GAME,
          {},
        );
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
      mockChannelContext.game.status = GAME_STATUS.IN_PROGRESS;
      mockChannelContext.game.turn = {
        phase: TURN_PHASE.WAITING,
        assumptions: [],
      };
    });

    describe("owner", () => {
      test("advances turn when ready is clicked", async () => {
        mockChannelContext.permissions.can_start_turn = true;

        renderForUser(ownerUser);

        await fireEvent.click(screen.getByRole("button", { name: "Ready" }));

        expect(mockChannelContext.channel.push).toHaveBeenCalledWith(
          PUSH_EVENT.ADVANCE_TURN,
          {},
        );
      });

      test("disables play button during waiting phase", () => {
        mockChannelContext.permissions.can_control_playback = false;

        renderForUser(ownerUser);

        const playButton = screen.getByRole("button", {
          name: "Play track",
        });
        expect(playButton).toBeDisabled();
      });
    });

    describe("player", () => {
      beforeEach(() => {
        mockChannelContext.game.cursor = 1;
      });

      test("disables play button during waiting phase", () => {
        mockChannelContext.permissions.can_control_playback = false;

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
      mockChannelContext.game.status = GAME_STATUS.IN_PROGRESS;
      mockChannelContext.game.turn = {
        phase: TURN_PHASE.READY,
        assumptions: [],
      };
    });

    describe("owner", () => {
      test("shows disabled forward button without advance permission", () => {
        mockChannelContext.permissions.can_control_playback = true;

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
        mockChannelContext.game.cursor = 1;
      });

      test("shows disabled forward button without advance permission", () => {
        mockChannelContext.permissions.can_control_playback = true;
        mockChannelContext.permissions.can_advance_turn = false;

        renderForUser(playerUser);

        expect(
          screen.getByRole("button", { name: "Play track" }),
        ).toBeEnabled();
        expect(
          screen.getByRole("button", { name: "Forward" }),
        ).toBeDisabled();
      });

      test("shows enabled forward button with advance permission", () => {
        mockChannelContext.permissions.can_control_playback = true;
        mockChannelContext.permissions.can_advance_turn = true;

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
        mockChannelContext.permissions.can_control_playback = false;
        mockChannelContext.permissions.can_advance_turn = false;

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
      mockChannelContext.game.status = GAME_STATUS.FINISHED;
      mockChannelContext.game.turn = null;
      mockChannelContext.permissions.can_restart_game = true;
      mockChannelContext.permissions.can_control_playback = true;
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
      mockChannelContext.game.player.is_playback = false;

      renderForUser(ownerUser);

      expect(
        screen.getByRole("button", { name: "Play track" }),
      ).toHaveAttribute("aria-pressed", "false");
    });

    test("sets aria-pressed=true when playing", () => {
      mockChannelContext.game.player.is_playback = true;
      mockChannelContext.permissions.can_control_playback = true;

      renderForUser(ownerUser);

      expect(
        screen.getByRole("button", { name: "Pause track" }),
      ).toHaveAttribute("aria-pressed", "true");
    });
  });
});
