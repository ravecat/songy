import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { GAME_STATUS } from "~shared/types/game";
import { TURN_PHASE } from "~shared/types/turn";
import { PUSH_EVENT } from "~shared/types/channel";
import * as GameContext from "~components/GameChannel.svelte";
import * as Scope from "~components/Scope.svelte";

import Player from "~components/Player.svelte";

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

  describe("waiting game | none turn", () => {
    beforeEach(() => {
      mockChannelContext.game.status = GAME_STATUS.WAITING;
      mockChannelContext.game.turn = null;
    });

    describe("owner", () => {
      test("shows ready button", () => {
        mockChannelContext.permissions.can_start_game = true;

        renderForUser(ownerUser);

        const readyButton = screen.getByRole("button", { name: "Ready" });

        expect(readyButton).toBeEnabled();
      });

      test("disables play button", () => {
        renderForUser(ownerUser);

        const playButton = screen.getByRole("button", { name: "Play track" });

        expect(playButton).toBeDisabled();
      });

      test("starts game when ready is clicked", async () => {
        mockChannelContext.permissions.can_start_game = true;

        renderForUser(ownerUser);

        await fireEvent.click(screen.getByRole("button", { name: "Ready" }));

        expect(mockChannelContext.channel.push).toHaveBeenCalledWith(
          PUSH_EVENT.START_GAME,
          {}
        );
      });
    });

    describe("challenger", () => {
      test("hides ready button", () => {
        renderForUser(playerUser);

        expect(
          screen.queryByRole("button", { name: "Ready" })
        ).not.toBeInTheDocument();
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
          {}
        );
      });

      test("disables play button during waiting phase", () => {
        mockChannelContext.permissions.can_control_playback = false;

        renderForUser(ownerUser);

        const playButton = screen.getByRole("button", { name: "Play track" });
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

        const playButton = screen.getByRole("button", { name: "Play track" });
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
      test("hides next", () => {
        mockChannelContext.permissions.can_control_playback = true;

        renderForUser(ownerUser);

        expect(
          screen.getByRole("button", { name: "Play track" })
        ).toBeEnabled();
        expect(
          screen.queryByRole("button", { name: "Next phase" })
        ).not.toBeInTheDocument();
      });
    });

    describe("player", () => {
      beforeEach(() => {
        mockChannelContext.game.cursor = 1;
      });

      test("shows next and enables play", () => {
        mockChannelContext.permissions.can_control_playback = true;
        mockChannelContext.permissions.can_advance_turn = true;

        renderForUser(playerUser);

        expect(
          screen.getByRole("button", { name: "Play track" })
        ).toBeEnabled();
        expect(
          screen.getByRole("button", { name: "Next phase" })
        ).toBeEnabled();
      });
    });

    describe("challenger", () => {
      test("disables play button", () => {
        mockChannelContext.permissions.can_control_playback = false;
        mockChannelContext.permissions.can_advance_turn = false;

        renderForUser(playerUser);

        expect(
          screen.getByRole("button", { name: "Play track" })
        ).toBeDisabled();
        expect(
          screen.queryByRole("button", { name: "Next phase" })
        ).not.toBeInTheDocument();
      });
    });
  });
});
