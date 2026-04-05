import { writable } from "svelte/store";
import { render } from "vitest-browser-svelte";
import { beforeEach, describe, expect, test, vi } from "vitest";

vi.mock("~/contexts/game");

import GameFinished from "~components/game_finished.svelte";
import { getGameContext } from "~/contexts/game";

describe("GameFinished", () => {
  let snapshot;

  beforeEach(() => {
    vi.clearAllMocks();
    snapshot = {
      game: {
        id: "game-1",
        owner_id: "owner-1",
        max_participants: 8,
        max_score: 10,
        status: "finished",
        participants: {
          "user-1": {
            uuid: "user-1",
            name: "Alice",
            avatar_url: "https://example.com/alice.jpg",
          },
          "user-2": {
            uuid: "user-2",
            name: "Bob",
            avatar_url: "https://example.com/bob.jpg",
          },
          "user-3": {
            uuid: "user-3",
            name: "Carol",
            avatar_url: "https://example.com/carol.jpg",
          },
        },
        scores: {
          "user-1": 7,
          "user-2": 10,
          "user-3": 3,
        },
        player: {
          is_playback: false,
        },
        timelines: {},
        created_at: "2026-01-01T00:00:00Z",
        queue: ["user-1", "user-2", "user-3"],
        cursor: 1,
        track: null,
        turn: {
          phase: "results",
          assumptions: {},
          winner_id: "user-2",
          deadline_at_ms: null,
        },
      },
      permissions: {
        can_control_playback: false,
        can_advance_turn: false,
        can_start_game: false,
        can_start_turn: false,
        can_restart_game: true,
        can_see_assumptions: true,
        can_make_assumptions: false,
      },
    };
  });

  test("shows winner and target score", async () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        snapshot,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(GameFinished);

    await expect
      .element(screen.getByRole("heading", { name: "Bob wins" }))
      .toBeVisible();
    await expect.element(screen.getByText("10/10 points")).toBeVisible();
    await expect.element(screen.getByText("Target 10")).toBeVisible();
  });

  test("sorts leaderboard by score descending", () => {
    vi.mocked(getGameContext).mockReturnValue(
      writable({
        snapshot,
        status: "ready",
        error: null,
      }),
    );

    const { container } = render(GameFinished);

    const leaderboard = Array.from(container.querySelectorAll(".game-finished__entry"));

    expect(leaderboard).toHaveLength(3);
    expect(leaderboard[0]?.textContent).toContain("Bob");
    expect(leaderboard[1]?.textContent).toContain("Alice");
    expect(leaderboard[2]?.textContent).toContain("Carol");
    expect(leaderboard[0]?.getAttribute("aria-current")).toBe("true");
  });

  test("falls back to user id when participant payload is missing", () => {
    delete snapshot.game.participants["user-3"];

    vi.mocked(getGameContext).mockReturnValue(
      writable({
        snapshot,
        status: "ready",
        error: null,
      }),
    );

    const { container } = render(GameFinished);

    const leaderboard = Array.from(container.querySelectorAll(".game-finished__entry"));
    const missingParticipantRow = leaderboard[2];

    expect(missingParticipantRow?.textContent).toContain("user-3");
    expect(
      missingParticipantRow?.querySelector(".game-finished__entry-score")?.textContent,
    ).toBe("3");
  });
});
