import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import * as GameContext from "~components/GameChannel.svelte";
import Participants from "~components/Participants.svelte";

describe("Participants component", () => {
  let getGameContextSpy;

  beforeEach(() => {
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("displays correct participant count", () => {
    const mockChannelContext = {
      game: {
        participants: [
          { uuid: "user-1", name: "Alice", avatar_url: "https://example.com/alice.jpg" },
          { uuid: "user-2", name: "Bob", avatar_url: "https://example.com/bob.jpg" },
          { uuid: "user-3", name: "Charlie", avatar_url: "https://example.com/charlie.jpg" },
        ],
      },
    };

    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Participants);

    expect(screen.getByText("3")).toBeInTheDocument();
    expect(screen.getByLabelText("3 players online")).toBeInTheDocument();
  });

  test("displays 0 when no participants", () => {
    const emptyChannelContext = {
      game: {
        participants: [],
      },
    };

    getGameContextSpy.mockReturnValue(emptyChannelContext);

    render(Participants);

    expect(screen.getByText("0")).toBeInTheDocument();
  });

  test("displays 1 player singular form", () => {
    const singleParticipantContext = {
      game: {
        participants: [
          { uuid: "user-1", name: "Alice", avatar_url: "https://example.com/alice.jpg" },
        ],
      },
    };

    getGameContextSpy.mockReturnValue(singleParticipantContext);

    render(Participants);

    expect(screen.getByText("1")).toBeInTheDocument();
    expect(screen.getByLabelText("1 player online")).toBeInTheDocument();
  });

  test("handles null game gracefully", () => {
    const nullGameContext = {
      game: null,
    };

    getGameContextSpy.mockReturnValue(nullGameContext);

    render(Participants);

    expect(screen.getByText("0")).toBeInTheDocument();
  });

  test("handles undefined participants gracefully", () => {
    const undefinedParticipantsContext = {
      game: {},
    };

    getGameContextSpy.mockReturnValue(undefinedParticipantsContext);

    render(Participants);

    expect(screen.getByText("0")).toBeInTheDocument();
  });

  test("renders Users icon", () => {
    const mockChannelContext = {
      game: {
        participants: [
          { uuid: "user-1", name: "Alice", avatar_url: "https://example.com/alice.jpg" },
        ],
      },
    };

    getGameContextSpy.mockReturnValue(mockChannelContext);

    const { container } = render(Participants);

    const svg = container.querySelector('svg');
    expect(svg).toBeInTheDocument();
    expect(svg).toHaveClass('lucide-users');
  });
});
