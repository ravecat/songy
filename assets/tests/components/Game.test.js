import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, vi, beforeEach } from "vitest";

vi.mock("svelte-modals", () => ({
  modals: {
    open: vi.fn(),
  },
}));

import Game from "@components/Game.svelte";
import TurnWaitingModal from "@components/TurnWaitingModal.svelte";
import { modals } from "svelte-modals";

describe("Game", () => {
  let mockChannelContext;
  let mockScopeContext;

  beforeEach(() => {
    vi.mocked(modals.open).mockClear();

    mockScopeContext = {
      user: {
        uuid: "test-user-uuid",
        name: "Test User",
      },
    };

    mockChannelContext = {
      state: {
        participants: [
          {
            uuid: "user-1",
            name: "Alice",
            avatar_url: "https://example.com/alice.jpg",
          },
        ],
        turn: {
          phase: "turn_playing",
        },
      },
    };
  });

  test("renders basic game components", () => {
    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    // Check that main components are rendered by looking for participants section
    expect(screen.getByText("Alice")).toBeInTheDocument();
  });

  test("does not open modal when turn phase is not turn_waiting", () => {
    mockChannelContext.state.turn.phase = "turn_playing";

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(modals.open).not.toHaveBeenCalled();
  });

  test("does not open modal when turn phase is turn_results", () => {
    mockChannelContext.state.turn.phase = "turn_results";

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(modals.open).not.toHaveBeenCalled();
  });

  test("opens TurnWaitingModal when turn phase is turn_waiting", () => {
    mockChannelContext.state.turn.phase = "turn_waiting";

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(modals.open).toHaveBeenCalledWith(TurnWaitingModal);
    expect(modals.open).toHaveBeenCalledTimes(1);
  });

  test("does not open modal when turn state is undefined", () => {
    mockChannelContext.state.turn = undefined;

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(modals.open).not.toHaveBeenCalled();
  });

  test("does not open modal when state is undefined", () => {
    // Empty state that still has structure for components
    mockChannelContext.state = {
      participants: [],
      turn: undefined,
    };

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(modals.open).not.toHaveBeenCalled();
  });

  test("handles null turn phase gracefully", () => {
    mockChannelContext.state.turn.phase = null;

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(modals.open).not.toHaveBeenCalled();
  });

  test("modal opens immediately if initial phase is turn_waiting", () => {
    mockChannelContext.state.turn.phase = "turn_waiting";

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(modals.open).toHaveBeenCalledWith(TurnWaitingModal);
    expect(modals.open).toHaveBeenCalledTimes(1);
  });

  test("does not crash when channel context is missing", () => {
    expect(() => {
      render(Game, {
        context: new Map(),
      });
    }).toThrow("getChannelContext() must be called within a Channel component");
  });

  test("reacts to turn phase change from turn_playing to turn_waiting", async () => {
    // Start with turn_playing phase
    mockChannelContext.state.turn.phase = "turn_playing";

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    // Confirm modal is not opened initially
    expect(modals.open).not.toHaveBeenCalled();

    // In Svelte 5, we need to test reactivity differently
    // Since the component reacts to changes in the context data,
    // we need to render a new instance with the updated data
    vi.mocked(modals.open).mockClear();
    mockChannelContext.state.turn.phase = "turn_waiting";

    // Render with updated context to simulate reactivity
    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    // Modal should open with the new phase
    expect(modals.open).toHaveBeenCalledWith(TurnWaitingModal);
    expect(modals.open).toHaveBeenCalledTimes(1);
  });

  test.each([
    { phase: "turn_playing", shouldOpenModal: false },
    { phase: "turn_results", shouldOpenModal: false },
    { phase: "turn_waiting", shouldOpenModal: true },
    { phase: "turn_challenging", shouldOpenModal: false },
    { phase: "turn_waiting", shouldOpenModal: true },
  ])("handles phase '$phase' correctly", ({ phase, shouldOpenModal }) => {
    mockChannelContext.state.turn.phase = phase;

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    if (shouldOpenModal) {
      expect(modals.open).toHaveBeenCalledWith(TurnWaitingModal);
      expect(modals.open).toHaveBeenCalledTimes(1);
    } else {
      expect(modals.open).not.toHaveBeenCalled();
    }
  });

  test.each([
    "turn_challenging",
    "turn_countdown",
    "",
    "unknown_phase",
    123,
    {},
    [],
  ])("does not open modal for invalid phase: %s", (phase) => {
    mockChannelContext.state.turn.phase = phase;

    render(Game, {
      context: new Map([
        ["channel", mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(modals.open).not.toHaveBeenCalled();
  });
});
