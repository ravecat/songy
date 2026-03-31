import { render, screen, within } from "@testing-library/svelte";
import { beforeEach, describe, expect, test } from "vitest";
import GameContextFixture from "../fixtures/game_context_fixture.svelte";

import GameFinished from "~components/game_finished.svelte";

describe("GameFinished", () => {
  let snapshot;

  function renderWithSession(session = { snapshot }) {
    return render(GameContextFixture, {
      component: GameFinished,
      session,
    });
  }

  beforeEach(() => {
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

  test("shows winner and target score", () => {
    renderWithSession();

    expect(
      screen.getByRole("heading", { name: "Bob wins" }),
    ).toBeInTheDocument();
    expect(screen.getByText("10/10 points")).toBeInTheDocument();
    expect(screen.getByText("Target 10")).toBeInTheDocument();
  });

  test("sorts leaderboard by score descending", () => {
    renderWithSession();

    const leaderboard = within(
      screen.getByRole("list", { name: "Final leaderboard" }),
    ).getAllByRole("listitem");

    expect(within(leaderboard[0]).getByText("Bob")).toBeInTheDocument();
    expect(within(leaderboard[1]).getByText("Alice")).toBeInTheDocument();
    expect(within(leaderboard[2]).getByText("Carol")).toBeInTheDocument();
    expect(leaderboard[0]).toHaveAttribute("aria-current", "true");
  });

  test("falls back to user id when participant payload is missing", () => {
    delete snapshot.game.participants["user-3"];

    renderWithSession();

    const leaderboard = within(
      screen.getByRole("list", { name: "Final leaderboard" }),
    ).getAllByRole("listitem");
    const missingParticipantRow = leaderboard[2];

    expect(within(missingParticipantRow).getByText("user-3")).toBeInTheDocument();
    expect(
      within(missingParticipantRow).getByText("3", {
        selector: ".game-finished__entry-score",
      }),
    ).toBeInTheDocument();
  });
});
