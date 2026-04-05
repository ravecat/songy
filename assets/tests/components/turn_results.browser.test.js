import { writable } from "svelte/store";
import { render } from "vitest-browser-svelte";
import { describe, expect, test, vi } from "vitest";

vi.mock("~/contexts/game");

import TurnResults from "~components/turn_results.svelte";
import { getGameContext } from "~/contexts/game";

describe("TurnResults", () => {
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

  test("renders track info", async () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        snapshot: {
          game: {
            track: mockTrack,
            participants: mockParticipants,
            turn: {
              phase: "results",
              assumptions: mockAssumptions,
              winner_id: "user-1",
            },
          },
        },
        status: "ready",
        error: null,
      }),
    );

    const screen = render(TurnResults);

    await expect.element(screen.getByText("Queen")).toBeVisible();
    await expect.element(screen.getByText("Bohemian Rhapsody")).toBeVisible();
    await expect.element(screen.getByText("1975")).toBeVisible();
  });

  test("displays all challengers avatars", async () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        snapshot: {
          game: {
            track: mockTrack,
            participants: mockParticipants,
            turn: {
              phase: "results",
              assumptions: mockAssumptions,
              winner_id: "user-1",
            },
          },
        },
        status: "ready",
        error: null,
      }),
    );

    const screen = render(TurnResults);

    await expect.element(screen.getByAltText("Alice")).toHaveAttribute(
      "src",
      "https://example.com/alice.jpg",
    );
    await expect.element(screen.getByAltText("Bob")).toHaveAttribute(
      "src",
      "https://example.com/bob.jpg",
    );
    await expect.element(screen.getByAltText("Charlie")).not.toBeInTheDocument();
  });

  test("displays challenger names", async () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        snapshot: {
          game: {
            track: mockTrack,
            participants: mockParticipants,
            turn: {
              phase: "results",
              assumptions: mockAssumptions,
              winner_id: "user-1",
            },
          },
        },
        status: "ready",
        error: null,
      }),
    );

    const screen = render(TurnResults);

    await expect.element(screen.getByText("Alice")).toBeVisible();
    await expect.element(screen.getByText("Bob")).toBeVisible();
  });

  test("highlights winner with score badge", () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        snapshot: {
          game: {
            track: mockTrack,
            participants: mockParticipants,
            turn: {
              phase: "results",
              assumptions: mockAssumptions,
              winner_id: "user-1",
            },
          },
        },
        status: "ready",
        error: null,
      }),
    );

    const { container } = render(TurnResults);

    const challengers = Array.from(container.querySelectorAll('[role="listitem"]'));
    const winner = challengers.find(
      (el) => el.getAttribute("aria-current") === "true",
    );

    expect(winner).toBeDefined();
    expect(container.textContent).toContain("+1");
  });

  test("only one challenger is marked as winner", () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        snapshot: {
          game: {
            track: mockTrack,
            participants: mockParticipants,
            turn: {
              phase: "results",
              assumptions: mockAssumptions,
              winner_id: "user-1",
            },
          },
        },
        status: "ready",
        error: null,
      }),
    );

    const { container } = render(TurnResults);

    const challengers = Array.from(container.querySelectorAll('[role="listitem"]'));
    const winners = challengers.filter(
      (el) => el.getAttribute("aria-current") === "true",
    );

    expect(challengers).toHaveLength(2);
    expect(winners).toHaveLength(1);
  });

  test("handles missing winner - no winner highlighted", () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        snapshot: {
          game: {
            track: mockTrack,
            participants: mockParticipants,
            turn: {
              phase: "results",
              assumptions: mockAssumptions,
              winner_id: null,
            },
          },
        },
        status: "ready",
        error: null,
      }),
    );

    const { container } = render(TurnResults);

    const challengers = Array.from(container.querySelectorAll('[role="listitem"]'));
    const winners = challengers.filter(
      (el) => el.getAttribute("aria-current") === "true",
    );

    expect(winners).toHaveLength(0);
    expect(container.textContent).not.toContain("+1");
  });
});
