import { render, screen } from "@testing-library/svelte";
import { describe, expect, test, beforeEach, vi, afterEach } from "vitest";
import { GAME_STATUS } from "~shared/types/game";
import Room from "~components/Room.svelte";
import * as GameContext from "~components/GameChannel.svelte";
import * as Scope from "~components/Scope.svelte";

describe("Room", () => {
  let getGameContextSpy;
  let getScopeContextSpy;
  let mockChannelContext;

  beforeEach(() => {
    mockChannelContext = {
      game: {
        scores: {
          "user-1": 7,
        },
        participants: [
          { uuid: "user-1", name: "Alice" },
          { uuid: "user-2", name: "Bob" },
        ],
        status: GAME_STATUS.WAITING,
        turn: null,
        player: {
          is_playback: false,
        },
        owner_id: "user-1",
        queue: ["user-1", "user-2"],
        cursor: 0,
      },
      permissions: {
        can_control_playback: false,
        can_advance_turn: false,
        can_start_game: false,
        can_start_turn: false,
        can_restart_game: false,
      },
      channel: {
        on: vi.fn(() => Symbol("ref")),
        off: vi.fn(),
        push: vi.fn(),
      },
    };

    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getScopeContextSpy = vi.spyOn(Scope, "getScopeContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders header and main components when game is active", () => {
    getGameContextSpy.mockReturnValue(mockChannelContext);
    getScopeContextSpy.mockReturnValue({
      user: { uuid: "user-1", name: "Alice" },
    });

    render(Room);

    expect(
      screen.getByRole("button", { name: "Your score: 7" }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "2 players online" }),
    ).toBeInTheDocument();
    expect(screen.getByText("waiting for players...")).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Play track" }),
    ).toBeInTheDocument();
  });
});
