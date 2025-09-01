import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach } from "vitest";
import { TURN_PHASE } from "~shared/types/turn";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import { SCOPE_CONTEXT_KEY } from "~components/Scope.svelte";

import CurrentTrack from "~components/CurrentTrack.svelte";

describe("CurrentTrack", () => {
  let mockChannelContext;
  let mockScopeContext;
  let mockTrack;

  beforeEach(() => {
    mockTrack = {
      id: "track123",
      title: "Test Song",
      artist: "Test Artist",
      year: 2023,
    };

    mockChannelContext = {
      state: {
        turn: {
          phase: TURN_PHASE.CHALLENGING,
          track: mockTrack,
          assumptions: [],
        },
      },
    };

    mockScopeContext = {
      user: {
        uuid: "user-1",
        name: "Test User",
      },
    };
  });

  describe("when user has NOT made an assumption", () => {
    test("renders timeline with current track", () => {
      render(CurrentTrack, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext],
          [SCOPE_CONTEXT_KEY, mockScopeContext],
        ]),
      });

      const timeline = screen.getByRole("list");
      expect(timeline).toBeInTheDocument();
    });

    test("displays track card with question mark (hidden track)", () => {
      render(CurrentTrack, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext],
          [SCOPE_CONTEXT_KEY, mockScopeContext],
        ]),
      });

      expect(screen.getByText("?")).toBeInTheDocument();
      expect(screen.queryByText("Test Song")).not.toBeInTheDocument();
      expect(screen.queryByText("Test Artist")).not.toBeInTheDocument();
    });
  });

  describe("when user HAS made an assumption", () => {
    beforeEach(() => {
      mockChannelContext.state.turn.assumptions = [
        {
          position: 0,
          user_id: "user-1",
        },
      ];
    });

    test("does not render timeline component", () => {
      render(CurrentTrack, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext],
          [SCOPE_CONTEXT_KEY, mockScopeContext],
        ]),
      });

      expect(screen.queryByRole("list")).not.toBeInTheDocument();
    });

    test("does not render track card", () => {
      render(CurrentTrack, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext],
          [SCOPE_CONTEXT_KEY, mockScopeContext],
        ]),
      });

      expect(screen.queryByText("?")).not.toBeInTheDocument();
      expect(screen.queryByText("Test Song")).not.toBeInTheDocument();
      expect(screen.queryByText("Test Artist")).not.toBeInTheDocument();
    });

    test("renders nothing (empty component)", () => {
      const { container } = render(CurrentTrack, {
        context: new Map([
          [GAME_CONTEXT_KEY, mockChannelContext],
          [SCOPE_CONTEXT_KEY, mockScopeContext],
        ]),
      });

      expect(container.textContent.trim()).toBe("");
    });
  });

  describe("required contexts", () => {
    test("throws error when gameContext is missing", () => {
      expect(() => {
        render(CurrentTrack, {
          context: new Map([[SCOPE_CONTEXT_KEY, mockScopeContext]]),
        });
      }).toThrow();
    });

    test("throws error when scope context is missing", () => {
      expect(() => {
        render(CurrentTrack, {
          context: new Map([[GAME_CONTEXT_KEY, mockChannelContext]]),
        });
      }).toThrow();
    });

    test("renders without error when both contexts are provided", () => {
      expect(() => {
        render(CurrentTrack, {
          context: new Map([
            [GAME_CONTEXT_KEY, mockChannelContext],
            [SCOPE_CONTEXT_KEY, mockScopeContext],
          ]),
        });
      }).not.toThrow();
    });
  });
});
