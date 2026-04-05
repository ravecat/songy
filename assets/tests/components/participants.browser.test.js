import { writable } from "svelte/store";
import { render } from "vitest-browser-svelte";
import { afterEach, describe, expect, test, vi } from "vitest";

vi.mock("~/contexts/game");

import Participants from "~components/participants.svelte";
import { getGameContext } from "~/contexts/game";

describe("Participants component", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("displays correct participant count", async () => {
    const mockChannelContext = {
      snapshot: {
        game: {
          participants: {
            "user-1": { uuid: "user-1", name: "Alice", avatar_url: "https://example.com/alice.jpg" },
            "user-2": { uuid: "user-2", name: "Bob", avatar_url: "https://example.com/bob.jpg" },
            "user-3": { uuid: "user-3", name: "Charlie", avatar_url: "https://example.com/charlie.jpg" },
          },
        },
      },
    };

    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...mockChannelContext,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(Participants);

    await expect.element(screen.getByText("3")).toBeVisible();
    await expect
      .element(screen.getByRole("status", { name: "3 players online" }))
      .toBeVisible();
  });

  test("displays 0 when no participants", async () => {
    const emptyChannelContext = {
      snapshot: {
        game: {
          participants: {},
        },
      },
    };

    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...emptyChannelContext,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(Participants);

    await expect.element(screen.getByText("0")).toBeVisible();
  });

  test("displays 1 player singular form", async () => {
    const singleParticipantContext = {
      snapshot: {
        game: {
          participants: {
            "user-1": { uuid: "user-1", name: "Alice", avatar_url: "https://example.com/alice.jpg" },
          },
        },
      },
    };

    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...singleParticipantContext,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(Participants);

    await expect.element(screen.getByText("1")).toBeVisible();
    await expect
      .element(screen.getByRole("status", { name: "1 player online" }))
      .toBeVisible();
  });

  test("handles null game gracefully", async () => {
    const nullGameContext = {
      snapshot: null,
    };

    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...nullGameContext,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(Participants);

    await expect.element(screen.getByText("0")).toBeVisible();
  });

  test("handles undefined participants gracefully", async () => {
    const undefinedParticipantsContext = {
      snapshot: {
        game: {},
      },
    };

    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...undefinedParticipantsContext,
        status: "ready",
        error: null,
      }),
    );

    const screen = render(Participants);

    await expect.element(screen.getByText("0")).toBeVisible();
  });

  test("renders Users icon", () => {
    const mockChannelContext = {
      snapshot: {
        game: {
          participants: {
            "user-1": { uuid: "user-1", name: "Alice", avatar_url: "https://example.com/alice.jpg" },
          },
        },
      },
    };

    vi.mocked(getGameContext).mockReturnValue(
      writable({
        ...mockChannelContext,
        status: "ready",
        error: null,
      }),
    );

    const { container } = render(Participants);

    const svg = container.querySelector('svg');
    expect(svg).not.toBeNull();
    expect(svg?.classList.contains("lucide-users")).toBe(true);
  });
});
