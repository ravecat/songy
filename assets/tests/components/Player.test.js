import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { Channel } from "phoenix";
import { GAME_STATUS } from "~shared/types/game";
import { TURN_PHASE } from "~shared/types/turn";
import { PUSH_EVENT } from "~shared/types/channel";
import * as GameContext from "~components/GameChannel.svelte";
import * as Scope from "~components/Scope.svelte";

import Player from "~components/Player.svelte";

vi.mock("phoenix");

describe("Player", () => {
  let mockChannelContext;
  let getScopeContextSpy;
  let getGameContextSpy;

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
      channel: new Channel("room:123", {}, null),
    };

    getScopeContextSpy = vi.spyOn(Scope, "getScopeContext");
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("shows Ready button for active player and disables Play during waiting", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Player);

    const readyButton = screen.getByRole("button", { name: "Ready" });
    const playButton = screen.getByRole("button", { name: "Play track" });

    expect(readyButton).toBeEnabled();
    expect(playButton).toBeDisabled();
  });

  test("disables Play and hides Ready for non-active player during waiting", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Player);

    expect(
      screen.queryByRole("button", { name: "Ready" })
    ).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Play track" })).toBeDisabled();
  });

  test("shows Next and enabled Play for active non-owner in ready phase", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };

    mockChannelContext.game.status = GAME_STATUS.IN_PROGRESS;
    mockChannelContext.game.turn = {
      phase: TURN_PHASE.READY,
      assumptions: [],
    };
    mockChannelContext.game.cursor = 1;

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Player);

    expect(screen.getByRole("button", { name: "Play track" })).toBeEnabled();
    expect(screen.getByRole("button", { name: "Next phase" })).toBeEnabled();
  });

  test("hides Next for owner in ready phase", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    mockChannelContext.game.status = GAME_STATUS.IN_PROGRESS;
    mockChannelContext.game.turn = {
      phase: TURN_PHASE.READY,
      assumptions: [],
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Player);

    expect(screen.getByRole("button", { name: "Play track" })).toBeEnabled();
    expect(
      screen.queryByRole("button", { name: "Next phase" })
    ).not.toBeInTheDocument();
  });

  test("disables Play for non-active player in ready phase", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };

    mockChannelContext.game.status = GAME_STATUS.IN_PROGRESS;
    mockChannelContext.game.turn = {
      phase: TURN_PHASE.READY,
      assumptions: [],
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Player);

    expect(screen.getByRole("button", { name: "Play track" })).toBeDisabled();
    expect(
      screen.queryByRole("button", { name: "Next phase" })
    ).not.toBeInTheDocument();
  });

  test("starts game when Ready is clicked while game is waiting", async () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Player);

    await fireEvent.click(screen.getByRole("button", { name: "Ready" }));

    expect(mockChannelContext.channel.push).toHaveBeenCalledWith(
      PUSH_EVENT.START_GAME,
      {}
    );
  });

  test("advances turn when Ready is clicked during waiting phase", async () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    mockChannelContext.game.status = GAME_STATUS.IN_PROGRESS;
    mockChannelContext.game.turn = {
      phase: TURN_PHASE.WAITING,
      assumptions: [],
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Player);

    await fireEvent.click(screen.getByRole("button", { name: "Ready" }));

    expect(mockChannelContext.channel.push).toHaveBeenCalledWith(
      PUSH_EVENT.NEXT_PHASE,
      {}
    );
  });
});
