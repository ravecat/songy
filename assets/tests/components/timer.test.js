import { render, screen } from "@testing-library/svelte";
import { tick } from "svelte";
import { describe, expect, test, beforeEach, vi, afterEach } from "vitest";
import { Channel } from "phoenix";
import { TURN_PHASE } from "~shared/types/turn";
import { BROADCAST_EVENT } from "~/shared/types/phoenix";
import Timer from "~components/timer.svelte";
import * as GameContext from "~components/game_channel.svelte";

vi.mock("phoenix");

describe("Timer", () => {
  let mockChannelContext;
  let getGameContextSpy;
  let timerCallback;

  beforeEach(() => {
    mockChannelContext = {
      game: {
        turn: {
          phase: TURN_PHASE.CHALLENGING,
          assumptions: {},
          winner_id: null,
        },
      },
      channel: {
        on: vi.fn((event, callback) => {
          if (event === BROADCAST_EVENT.TIMER) {
            timerCallback = callback;
          }
          return Symbol("ref");
        }),
        off: vi.fn(),
      },
    };

    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
    timerCallback = null;
  });

  test("does not render when seconds is null", async () => {
    getGameContextSpy.mockReturnValue(mockChannelContext);
    render(Timer);

    await tick();

    expect(screen.queryByRole("timer")).not.toBeInTheDocument();
  });

  test("renders remaining seconds", async () => {
    getGameContextSpy.mockReturnValue(mockChannelContext);
    render(Timer);

    // Simulate timer event
    if (timerCallback) {
      timerCallback({ remaining: 12 });
    }
    await tick();

    expect(screen.getByRole("timer")).toHaveTextContent("12");
  });
});
