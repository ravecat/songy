import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import { Channel } from "phoenix";
import { TURN_PHASE } from "~shared/types/turn";
import * as GameContext from "~components/GameChannel.svelte";
import * as Scope from "~components/Scope.svelte";

import TurnChallenging from "~components/TurnChallenging.svelte";

vi.mock("phoenix");

describe("TurnChallenging", () => {
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
          {
            uuid: "user-2",
            name: "Bob",
            avatar_url: "https://example.com/bob.jpg",
          },
        ],
        queue: ["user-1", "user-2"],
        cursor: 0,
        status: "in_progress",
        track: {
          id: "current-track",
          title: "Current Track",
          artist: "Current Artist",
          year: 2020,
        },
        turn: {
          phase: TURN_PHASE.CHALLENGING,
          timeline: [
            {
              id: "timeline-track",
              title: "Timeline Track",
              artist: "Timeline Artist",
              year: 2019,
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
        uuid: "user-2",
        name: "Bob",
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnChallenging);

    const lists = screen.getAllByRole("list");
    expect(lists.length).toBeGreaterThan(0);
  });

  test("renders timeline item details for non-current track", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };

    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(TurnChallenging);

    expect(screen.getAllByText("Timeline Artist").length).toBeGreaterThan(0);
    expect(screen.getAllByText("2019").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Timeline Track").length).toBeGreaterThan(0);
  });
});
