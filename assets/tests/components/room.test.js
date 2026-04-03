import { render, screen, within } from "@testing-library/svelte";
import { fireEvent } from "@testing-library/svelte";
import { readable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import * as Inertia from "@inertiajs/svelte";
import { currentUser } from "~/stores/scope";
import Lobby from "~components/lobby.svelte";
import Room from "~components/room.svelte";
import GameContextFixture from "../fixtures/game_context_fixture.svelte";

vi.mock("~/stores/scope", async () => {
  const { writable } = await import("svelte/store");

  return {
    currentUser: writable(null),
    provider: writable(undefined),
  };
});

vi.mock("@inertiajs/svelte", async () => {
  const actual = await vi.importActual("@inertiajs/svelte");

  return {
    ...actual,
    inertia: () => ({
      destroy() {},
    }),
    usePage: vi.fn(),
  };
});

describe("Room", () => {
  function renderRoom(session) {
    return render(GameContextFixture, {
      component: Room,
      session,
    });
  }

  function renderLobby(session) {
    return render(GameContextFixture, {
      component: Lobby,
      session,
    });
  }

  beforeEach(() => {
    currentUser.set(users.alice);

    setPage({ qr: "<svg data-testid='room-qr'></svg>" });

    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    });

    Object.defineProperty(window, "location", {
      configurable: true,
      value: { href: "https://example.com/game/abc123" },
      writable: true,
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("screen", () => {
    test("renders loading state when game is unavailable", () => {
      renderRoom({
        snapshot: null,
      });

      expect(
        screen.getByRole("status", { name: "loading" }),
      ).toBeInTheDocument();
      expect(screen.queryByRole("main")).not.toBeInTheDocument();
    });

    test("renders owner lobby state without Storybook", () => {
      currentUser.set(users.alice);
      renderRoom(buildSession({
        permissions: {
          can_start_game: true,
        },
      }));

      const players = screen.getByRole("list", { name: "Lobby players" });

      expect(within(players).getAllByRole("listitem")).toHaveLength(3);
      expect(
        screen.getByRole("status", { name: "3 players online" }),
      ).toBeInTheDocument();
      expect(
        screen.getByRole("button", { name: "Copy share link" }),
      ).toBeInTheDocument();
      expect(
        screen.getByRole("button", { name: "Play track" }),
      ).toBeInTheDocument();
      expect(
        screen.getByRole("button", { name: "Start game" }),
      ).toBeInTheDocument();
      expect(
        screen.queryByRole("button", { name: "Forward" }),
      ).not.toBeInTheDocument();
      expect(screen.getByTestId("room-qr")).toBeInTheDocument();
    });

    test("renders player lobby state without Storybook", () => {
      currentUser.set(users.bob);
      renderRoom(buildSession());

      const players = screen.getByRole("list", { name: "Lobby players" });

      expect(within(players).getAllByRole("listitem")).toHaveLength(3);
      expect(
        screen.getByRole("status", { name: "3 players online" }),
      ).toBeInTheDocument();
      expect(
        screen.getByRole("button", { name: "Copy share link" }),
      ).toBeInTheDocument();
      expect(
        screen.getByRole("button", { name: "Play track" }),
      ).toBeInTheDocument();
      expect(
        screen.getByRole("button", { name: "Forward" }),
      ).toBeInTheDocument();
      expect(
        screen.queryByRole("button", { name: "Start game" }),
      ).not.toBeInTheDocument();
    });
  });

  describe("lobby", () => {
    test("renders lobby structure with players list and share button", () => {
      renderLobby({
        snapshot: {
          game: buildGame(),
          permissions: { ...basePermissions },
        },
      });

      expect(
        screen.getByRole("list", { name: "Lobby players" }),
      ).toBeInTheDocument();
      expect(screen.getAllByRole("listitem")).toHaveLength(3);
      expect(
        screen.getByRole("button", { name: "Copy share link" }),
      ).toBeInTheDocument();
    });

    test("displays all participants with avatars and names", () => {
      renderLobby({
        snapshot: {
          game: buildGame(),
          permissions: { ...basePermissions },
        },
      });

      for (const name of ["Alice", "Bob", "Carol"]) {
        expect(screen.getByAltText(name)).toBeInTheDocument();
        expect(screen.getByText(name)).toBeInTheDocument();
      }
    });

    test("shows crown badge for room owner", () => {
      renderLobby({
        snapshot: {
          game: buildGame(),
          permissions: { ...basePermissions },
        },
      });

      const players = within(
        screen.getByRole("list", { name: "Lobby players" }),
      ).getAllByRole("listitem");

      const ownerPlayer = players.find((player) =>
        within(player).queryByText("Alice"),
      );

      expect(ownerPlayer).toBeInTheDocument();
      expect(
        within(ownerPlayer).getByRole("img", { hidden: true }),
      ).toBeInTheDocument();
    });

    test("renders share button with URL", () => {
      renderLobby({
        snapshot: {
          game: buildGame(),
          permissions: { ...basePermissions },
        },
      });

      const shareButton = screen.getByRole("button", {
        name: "Copy share link",
      });

      expect(
        within(shareButton).getByText(/example\.com\/game\/abc123/),
      ).toBeInTheDocument();
    });

    test("renders QR svg when page props provide it", () => {
      setPage({ qr: "<svg data-testid='qr-svg'></svg>" });
      renderLobby({
        snapshot: {
          game: buildGame(),
          permissions: { ...basePermissions },
        },
      });

      expect(screen.getByTestId("qr-svg")).toBeInTheDocument();
    });

    test("copies URL to clipboard on share button click", async () => {
      renderLobby({
        snapshot: {
          game: buildGame(),
          permissions: { ...basePermissions },
        },
      });

      await fireEvent.click(
        screen.getByRole("button", { name: "Copy share link" }),
      );

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
        "https://example.com/game/abc123",
      );
    });

    test("shows copied state after clicking share button", async () => {
      renderLobby({
        snapshot: {
          game: buildGame(),
          permissions: { ...basePermissions },
        },
      });

      const shareButton = screen.getByRole("button", {
        name: "Copy share link",
      });

      await fireEvent.click(shareButton);

      expect(screen.getByText("Copied!")).toBeInTheDocument();
      expect(shareButton).toBeDisabled();
    });

    test("handles empty participants list", () => {
      renderLobby({
        snapshot: {
          game: buildGame({
            participants: {},
            queue: [],
          }),
          permissions: { ...basePermissions },
        },
      });

      const players = screen.getByRole("list", { name: "Lobby players" });
      expect(within(players).queryAllByRole("listitem")).toHaveLength(0);
    });

    test("handles missing game context gracefully", () => {
      renderLobby({
        snapshot: null,
      });

      expect(
        screen.getByRole("list", { name: "Lobby players" }),
      ).toBeInTheDocument();
      expect(screen.queryAllByRole("listitem")).toHaveLength(0);
      expect(
        screen.getByRole("button", { name: "Copy share link" }),
      ).toBeInTheDocument();
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

function buildSession({ game = {}, permissions = {} } = {}) {
  return {
    snapshot: {
      game: buildGame(game),
      permissions: {
        ...basePermissions,
        ...permissions,
      },
    },
    status: "ready",
    error: null,
    commands: {
      startGame: vi.fn(),
      advanceTurn: vi.fn(),
      makeAssumption: vi.fn(),
      startPlayback: vi.fn(),
      pausePlayback: vi.fn(),
    },
  };
}
