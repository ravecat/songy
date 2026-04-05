import { readable, writable } from "svelte/store";
import { render } from "vitest-browser-svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import * as Inertia from "@inertiajs/svelte";
import { currentUser } from "~/stores/scope";

vi.mock("~/contexts/game");

vi.mock("~/stores/scope", async () => {
  const { writable } = await import("svelte/store");

  return {
    currentUser: writable(null),
    provider: writable(undefined),
  };
});

vi.mock(import("@inertiajs/svelte"), async (importOriginal) => {
  const actual = await importOriginal();

  return {
    ...actual,
    inertia: () => ({
      destroy() {},
    }),
    usePage: vi.fn(),
  };
});

import Lobby from "~components/lobby.svelte";
import Room from "~components/room.svelte";
import { getGameContext } from "~/contexts/game";

describe("Room", () => {
  beforeEach(() => {
    vi.clearAllMocks();

    currentUser.set(users.alice);
    setPage({ qr: "<svg data-testid='room-qr'></svg>" });

    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    });

    window.history.replaceState({}, "", "/game/abc123");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("screen", () => {
    test("renders loading state when game is unavailable", async () => {
      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: null,
          status: "loading",
          error: null,
        }),
      );

      const screen = render(Room);

      await expect
        .element(screen.getByRole("status", { name: "loading" }))
        .toBeVisible();
      await expect.element(screen.getByRole("main")).not.toBeInTheDocument();
    });

    test("renders owner lobby state without Storybook", async () => {
      currentUser.set(users.alice);

      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: {
            game: buildGame(),
            permissions: {
              ...basePermissions,
              can_start_game: true,
            },
          },
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Room);

      expect(
        screen.container.querySelectorAll('[role="listitem"]').length,
      ).toBe(3);
      await expect
        .element(screen.getByRole("status", { name: "3 players online" }))
        .toBeVisible();
      await expect
        .element(screen.getByRole("button", { name: "Copy share link" }))
        .toBeVisible();
      await expect
        .element(screen.getByRole("button", { name: "Play track" }))
        .toBeVisible();
      await expect
        .element(screen.getByRole("button", { name: "Start game" }))
        .toBeVisible();
      await expect
        .element(screen.getByRole("button", { name: "Forward" }))
        .not.toBeInTheDocument();
      await expect.element(screen.getByTestId("room-qr")).toBeVisible();
    });

    test("renders player lobby state without Storybook", async () => {
      currentUser.set(users.bob);

      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: {
            game: buildGame(),
            permissions: { ...basePermissions },
          },
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Room);

      expect(
        screen.container.querySelectorAll('[role="listitem"]').length,
      ).toBe(3);
      await expect
        .element(screen.getByRole("status", { name: "3 players online" }))
        .toBeVisible();
      await expect
        .element(screen.getByRole("button", { name: "Copy share link" }))
        .toBeVisible();
      await expect
        .element(screen.getByRole("button", { name: "Play track" }))
        .toBeVisible();
      await expect
        .element(screen.getByRole("button", { name: "Forward" }))
        .toBeVisible();
      await expect
        .element(screen.getByRole("button", { name: "Start game" }))
        .not.toBeInTheDocument();
    });
  });

  describe("lobby", () => {
    test("renders lobby structure with players list and share button", async () => {
      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: {
            game: buildGame(),
            permissions: { ...basePermissions },
          },
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Lobby);

      await expect
        .element(screen.getByRole("list", { name: "Lobby players" }))
        .toBeVisible();
      expect(screen.container.querySelectorAll('[role="listitem"]').length).toBe(3);
      await expect
        .element(screen.getByRole("button", { name: "Copy share link" }))
        .toBeVisible();
    });

    test("displays all participants with avatars and names", async () => {
      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: {
            game: buildGame(),
            permissions: { ...basePermissions },
          },
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Lobby);

      for (const name of ["Alice", "Bob", "Carol"]) {
        await expect.element(screen.getByAltText(name)).toHaveAttribute(
          "src",
          users[name.toLowerCase()].avatar_url,
        );
        await expect.element(screen.getByText(name)).toBeVisible();
      }
    });

    test("shows crown badge for room owner", () => {
      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: {
            game: buildGame(),
            permissions: { ...basePermissions },
          },
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Lobby);

      const players = Array.from(screen.container.querySelectorAll('[role="listitem"]'));
      const ownerPlayer = players.find((player) => player.textContent?.includes("Alice"));

      expect(ownerPlayer).toBeDefined();
      expect(ownerPlayer?.querySelector(".lobby-player__badge")).not.toBeNull();
    });

    test("renders share button with URL", async () => {
      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: {
            game: buildGame(),
            permissions: { ...basePermissions },
          },
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Lobby);

      await expect
        .element(screen.getByText(window.location.href))
        .toBeVisible();
    });

    test("renders QR svg when page props provide it", async () => {
      setPage({ qr: "<svg data-testid='qr-svg'></svg>" });

      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: {
            game: buildGame(),
            permissions: { ...basePermissions },
          },
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Lobby);

      await expect.element(screen.getByTestId("qr-svg")).toBeVisible();
    });

    test("copies URL to clipboard on share button click", async () => {
      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: {
            game: buildGame(),
            permissions: { ...basePermissions },
          },
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Lobby);

      await screen.getByRole("button", { name: "Copy share link" }).click();

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
        window.location.href,
      );
    });

    test("shows copied state after clicking share button", async () => {
      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: {
            game: buildGame(),
            permissions: { ...basePermissions },
          },
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Lobby);

      const shareButton = screen.getByRole("button", {
        name: "Copy share link",
      });

      await shareButton.click();

      await expect.element(screen.getByText("Copied!")).toBeVisible();
      await expect.element(shareButton).toBeDisabled();
    });

    test("handles empty participants list", async () => {
      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: {
            game: buildGame({
              participants: {},
              queue: [],
            }),
            permissions: { ...basePermissions },
          },
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Lobby);

      expect(
        screen.container.querySelector('[role="list"][aria-label="Lobby players"]'),
      ).not.toBeNull();
      expect(screen.container.querySelectorAll('[role="listitem"]').length).toBe(0);
    });

    test("handles missing game context gracefully", async () => {
      vi.mocked(getGameContext).mockReturnValue(
        writable({
          snapshot: null,
          status: "ready",
          error: null,
        }),
      );

      const screen = render(Lobby);

      expect(
        screen.container.querySelector('[role="list"][aria-label="Lobby players"]'),
      ).not.toBeNull();
      expect(screen.container.querySelectorAll('[role="listitem"]').length).toBe(0);
      await expect
        .element(screen.getByRole("button", { name: "Copy share link" }))
        .toBeVisible();
    });
  });
});

const users = {
  alice: {
    uuid: "user-1",
    name: "Alice",
    avatar_url: "https://example.com/alice.jpg",
  },
  bob: {
    uuid: "user-2",
    name: "Bob",
    avatar_url: "https://example.com/bob.jpg",
  },
  carol: {
    uuid: "user-3",
    name: "Carol",
    avatar_url: "https://example.com/carol.jpg",
  },
};

const baseGame = {
  id: "room-1",
  owner_id: users.alice.uuid,
  max_participants: 8,
  max_score: 10,
  status: "waiting",
  participants: {
    [users.alice.uuid]: users.alice,
    [users.bob.uuid]: users.bob,
    [users.carol.uuid]: users.carol,
  },
  scores: {
    [users.alice.uuid]: 7,
    [users.bob.uuid]: 4,
    [users.carol.uuid]: 6,
  },
  player: {
    is_playback: false,
  },
  timelines: {
    [users.alice.uuid]: [],
    [users.bob.uuid]: [],
    [users.carol.uuid]: [],
  },
  created_at: "2026-03-23T12:00:00.000Z",
  queue: [users.alice.uuid, users.bob.uuid, users.carol.uuid],
  cursor: 0,
  track: null,
  turn: null,
};

const basePermissions = {
  can_control_playback: false,
  can_advance_turn: false,
  can_start_game: false,
  can_start_turn: false,
  can_restart_game: false,
  can_see_assumptions: false,
  can_make_assumptions: false,
};

function setPage(props = {}) {
  Inertia.usePage.mockReturnValue(
    readable({
      component: "room",
      props,
      url: "/room-1",
      version: null,
    }),
  );
}

function buildGame(game = {}) {
  return {
    ...baseGame,
    ...game,
  };
}
