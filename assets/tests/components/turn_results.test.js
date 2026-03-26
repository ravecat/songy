import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import * as GameContext from "~/contexts/game";

import TurnResults from "~components/turn_results.svelte";

describe("TurnResults", () => {
  let getGameContextSpy;

  const mockTrack = {
    id: "track-1",
    title: "Bohemian Rhapsody",
    artist: "Queen",
    year: 1975,
    cover_url: "https://example.com/cover.jpg",
    meta: {},
  };

  const mockParticipants = {
    "user-1": {
      uuid: "user-1",
      name: "Alice",
      avatar_url: "https://example.com/alice.jpg",
    },
    "user-2": { uuid: "user-2", name: "Bob", avatar_url: "https://example.com/bob.jpg" },
    "user-3": {
      uuid: "user-3",
      name: "Charlie",
      avatar_url: "https://example.com/charlie.jpg",
    },
  };

  const mockAssumptions = {
    "1": "user-1",
    "2": "user-2",
  };

  beforeEach(() => {
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders track info", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        track: mockTrack,
        participants: mockParticipants,
        turn: {
          phase: "results",
          assumptions: mockAssumptions,
          winner_id: "user-1",
        },
      },
    });

    render(TurnResults);

    expect(screen.getByText("Queen")).toBeInTheDocument();
    expect(screen.getByText("Bohemian Rhapsody")).toBeInTheDocument();
    expect(screen.getByText("1975")).toBeInTheDocument();
  });

  test("displays all challengers avatars", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        track: mockTrack,
        participants: mockParticipants,
        turn: {
          phase: "results",
          assumptions: mockAssumptions,
          winner_id: "user-1",
        },
      },
    });

    render(TurnResults);

    const aliceAvatar = screen.getByAltText("Alice");
    const bobAvatar = screen.getByAltText("Bob");

    expect(aliceAvatar).toBeInTheDocument();
    expect(aliceAvatar).toHaveAttribute("src", "https://example.com/alice.jpg");

    expect(bobAvatar).toBeInTheDocument();
    expect(bobAvatar).toHaveAttribute("src", "https://example.com/bob.jpg");

    expect(screen.queryByAltText("Charlie")).not.toBeInTheDocument();
  });

  test("displays challenger names", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        track: mockTrack,
        participants: mockParticipants,
        turn: {
          phase: "results",
          assumptions: mockAssumptions,
          winner_id: "user-1",
        },
      },
    });

    render(TurnResults);

    expect(screen.getByText("Alice")).toBeInTheDocument();
    expect(screen.getByText("Bob")).toBeInTheDocument();
  });

  test("highlights winner with score badge", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        track: mockTrack,
        participants: mockParticipants,
        turn: {
          phase: "results",
          assumptions: mockAssumptions,
          winner_id: "user-1",
        },
      },
    });

    render(TurnResults);

    const challengers = screen.getAllByRole("listitem");
    const winner = challengers.find(
      (el) => el.getAttribute("aria-current") === "true",
    );

    expect(winner).toBeInTheDocument();
    expect(screen.getByText("+1")).toBeInTheDocument();
  });

  test("only one challenger is marked as winner", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        track: mockTrack,
        participants: mockParticipants,
        turn: {
          phase: "results",
          assumptions: mockAssumptions,
          winner_id: "user-1",
        },
      },
    });

    render(TurnResults);

    const challengers = screen.getAllByRole("listitem");
    const winners = challengers.filter(
      (el) => el.getAttribute("aria-current") === "true",
    );

    expect(challengers).toHaveLength(2);
    expect(winners).toHaveLength(1);
  });

  test("handles missing winner - no winner highlighted", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        track: mockTrack,
        participants: mockParticipants,
        turn: {
          phase: "results",
          assumptions: mockAssumptions,
          winner_id: null,
        },
      },
    });

    render(TurnResults);

    const challengers = screen.getAllByRole("listitem");
    const winners = challengers.filter(
      (el) => el.getAttribute("aria-current") === "true",
    );

    expect(winners).toHaveLength(0);
    expect(screen.queryByText("+1")).not.toBeInTheDocument();
  });
});
