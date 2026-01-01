import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { Channel } from "phoenix";
import { TURN_PHASE } from "~shared/types/turn";
import * as GameContext from "~components/GameChannel.svelte";
import * as Scope from "~components/Scope.svelte";

import TurnResults from "~components/TurnResults.svelte";

vi.mock("phoenix");

describe("Turn results view", () => {
  let mockChannelContext;
  let getScopeContextSpy;
  let getGameContextSpy;

  beforeEach(() => {
    mockChannelContext = {
      game: {
        participants: [
          {
            uuid: "user-1",
            name: "Alice",
            avatar_url: "https://example.com/alice.jpg",
          },
        ],
        queue: ["user-1"],
        cursor: 0,
        status: "in_progress",
        track: {
          id: "track-1",
          title: "Wake Up",
          artist: "Example Band",
          year: 2021,
        },
        turn: {
          phase: TURN_PHASE.RESULTS,
          timeline: [
            {
              id: "track-1",
              title: "Wake Up",
              artist: "Example Band",
              year: 2021,
            },
          ],
          assumptions: [],
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

  test("renders active timeline list", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnResults);

    expect(screen.getByRole("list")).toBeInTheDocument();
  });

  test("renders track details when timeline has items", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Alice",
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnResults);

    expect(screen.getByText("Example Band")).toBeInTheDocument();
    expect(screen.getByText("2021")).toBeInTheDocument();
    expect(screen.getByText("Wake Up")).toBeInTheDocument();
  });
});
