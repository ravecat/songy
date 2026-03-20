import { render, screen } from "@testing-library/svelte";
import { describe, expect, test, beforeEach, vi, afterEach } from "vitest";
import { GAME_STATUS } from "~shared/types/game";
import Room from "~components/room.svelte";
import * as GameContext from "~components/game_channel.svelte";
import * as Scope from "~components/scope.svelte";
import * as QrContext from "~components/qr_context.svelte";

describe("Room", () => {
  let getGameContextSpy;
  let getQrContextSpy;
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
    getQrContextSpy = vi.spyOn(QrContext, "getQrContext");
    getQrContextSpy.mockReturnValue({ svg: "" });
    getScopeContextSpy = vi.spyOn(Scope, "getScopeContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders header and main components when game is active", () => {
    mockChannelContext.game.participants = [
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
    ];

    getGameContextSpy.mockReturnValue(mockChannelContext);
    getScopeContextSpy.mockReturnValue({
      user: { uuid: "user-1", name: "Alice" },
    });

    render(Room);

    expect(
      screen.getByRole("button", { name: "Your score: 7" }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole("status", { name: "2 players online" }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Copy share link" }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Play track" }),
    ).toBeInTheDocument();
  });
});
