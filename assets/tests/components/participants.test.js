import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import Participants from "~components/participants.svelte";
import GameContextFixture from "../fixtures/game_context_fixture.svelte";

describe("Participants component", () => {
  function renderWithSession(session) {
    return render(GameContextFixture, {
      component: Participants,
      session,
    });
  }

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("displays correct participant count", () => {
    const mockChannelContext = {
      snapshot: {
        game: {
          participants: [
            { uuid: "user-1", name: "Alice", avatar_url: "https://example.com/alice.jpg" },
            { uuid: "user-2", name: "Bob", avatar_url: "https://example.com/bob.jpg" },
            { uuid: "user-3", name: "Charlie", avatar_url: "https://example.com/charlie.jpg" },
          ],
        },
      },
    };

    renderWithSession(mockChannelContext);

    expect(screen.getByText("3")).toBeInTheDocument();
    expect(screen.getByLabelText("3 players online")).toBeInTheDocument();
  });

  test("displays 0 when no participants", () => {
    const emptyChannelContext = {
      snapshot: {
        game: {
          participants: [],
        },
      },
    };

    renderWithSession(emptyChannelContext);

    expect(screen.getByText("0")).toBeInTheDocument();
  });

  test("displays 1 player singular form", () => {
    const singleParticipantContext = {
      snapshot: {
        game: {
          participants: [
            { uuid: "user-1", name: "Alice", avatar_url: "https://example.com/alice.jpg" },
          ],
        },
      },
    };

    renderWithSession(singleParticipantContext);

    expect(screen.getByText("1")).toBeInTheDocument();
    expect(screen.getByLabelText("1 player online")).toBeInTheDocument();
  });

  test("handles null game gracefully", () => {
    const nullGameContext = {
      snapshot: null,
    };

    renderWithSession(nullGameContext);

    expect(screen.getByText("0")).toBeInTheDocument();
  });

  test("handles undefined participants gracefully", () => {
    const undefinedParticipantsContext = {
      snapshot: {
        game: {},
      },
    };

    renderWithSession(undefinedParticipantsContext);

    expect(screen.getByText("0")).toBeInTheDocument();
  });

  test("renders Users icon", () => {
    const mockChannelContext = {
      snapshot: {
        game: {
          participants: [
            { uuid: "user-1", name: "Alice", avatar_url: "https://example.com/alice.jpg" },
          ],
        },
      },
    };

    const { container } = renderWithSession(mockChannelContext);

    const svg = container.querySelector('svg');
    expect(svg).toBeInTheDocument();
    expect(svg).toHaveClass('lucide-users');
  });
});
