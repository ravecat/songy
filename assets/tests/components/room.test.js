import { render, screen, within } from "@testing-library/svelte";
import { fireEvent } from "@testing-library/svelte";
import { readable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import * as Inertia from "@inertiajs/svelte";
import * as GameContext from "~/contexts/game";
import * as Scope from "~components/scope.svelte";
import Lobby from "~components/lobby.svelte";
import Room from "~components/room.svelte";

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
  let getGameContextSpy;
  let getScopeContextSpy;

  beforeEach(() => {
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getScopeContextSpy = vi.spyOn(Scope, "getScopeContext");

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
      getGameContextSpy.mockReturnValue({
        game: null,
      });

      render(Room);

      expect(
        screen.getByRole("status", { name: "loading" }),
      ).toBeInTheDocument();
      expect(screen.queryByRole("main")).not.toBeInTheDocument();
    });

    test("renders owner lobby state without Storybook", () => {
      getScopeContextSpy.mockReturnValue({ user: users.alice });
      getGameContextSpy.mockReturnValue(
        buildSession({
          permissions: {
            can_start_game: true,
          },
        }),
      );

      render(Room);

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
      getScopeContextSpy.mockReturnValue({ user: users.bob });
      getGameContextSpy.mockReturnValue(buildSession());

      render(Room);

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
      getGameContextSpy.mockReturnValue({
        game: buildGame(),
      });

      render(Lobby);

      expect(
        screen.getByRole("list", { name: "Lobby players" }),
      ).toBeInTheDocument();
      expect(screen.getAllByRole("listitem")).toHaveLength(3);
      expect(
        screen.getByRole("button", { name: "Copy share link" }),
      ).toBeInTheDocument();
    });

    test("displays all participants with avatars and names", () => {
      getGameContextSpy.mockReturnValue({
        game: buildGame(),
      });

      render(Lobby);

      for (const name of ["Alice", "Bob", "Carol"]) {
        expect(screen.getByAltText(name)).toBeInTheDocument();
        expect(screen.getByText(name)).toBeInTheDocument();
      }
    });

    test("shows crown badge for room owner", () => {
      getGameContextSpy.mockReturnValue({
        game: buildGame(),
      });

      render(Lobby);

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
      getGameContextSpy.mockReturnValue({
        game: buildGame(),
      });

      render(Lobby);

      const shareButton = screen.getByRole("button", {
        name: "Copy share link",
      });

      expect(
        within(shareButton).getByText(/example\.com\/game\/abc123/),
      ).toBeInTheDocument();
    });

    test("renders QR svg when page props provide it", () => {
      getGameContextSpy.mockReturnValue({
        game: buildGame(),
      });
      setPage({ qr: "<svg data-testid='qr-svg'></svg>" });

      render(Lobby);

      expect(screen.getByTestId("qr-svg")).toBeInTheDocument();
    });

    test("copies URL to clipboard on share button click", async () => {
      getGameContextSpy.mockReturnValue({
        game: buildGame(),
      });

      render(Lobby);

      await fireEvent.click(
        screen.getByRole("button", { name: "Copy share link" }),
      );

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
        "https://example.com/game/abc123",
      );
    });

    test("shows copied state after clicking share button", async () => {
      getGameContextSpy.mockReturnValue({
        game: buildGame(),
      });

      render(Lobby);

      const shareButton = screen.getByRole("button", {
        name: "Copy share link",
      });

      await fireEvent.click(shareButton);

      expect(screen.getByText("Copied!")).toBeInTheDocument();
      expect(shareButton).toBeDisabled();
    });

    test("handles empty participants list", () => {
      getGameContextSpy.mockReturnValue({
        game: buildGame({
          participants: {},
          queue: [],
        }),
      });

      render(Lobby);

      const players = screen.getByRole("list", { name: "Lobby players" });
      expect(within(players).queryAllByRole("listitem")).toHaveLength(0);
    });

    test("handles missing game context gracefully", () => {
      getGameContextSpy.mockReturnValue({
        game: null,
      });

      render(Lobby);

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
    game: buildGame(game),
    permissions: {
      ...basePermissions,
      ...permissions,
    },
    timer: null,
    connection: "ready",
    error: null,
    startGame: vi.fn().mockResolvedValue(undefined),
    advanceTurn: vi.fn().mockResolvedValue(undefined),
    makeAssumption: vi.fn().mockResolvedValue(undefined),
    startPlayback: vi.fn().mockResolvedValue(undefined),
    pausePlayback: vi.fn().mockResolvedValue(undefined),
    updateProvider: vi.fn().mockResolvedValue(undefined),
    getProvider: vi.fn().mockResolvedValue({ token: "" }),
  };
}
