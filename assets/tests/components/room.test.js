import { screen, within } from "@testing-library/svelte";
import { composeStories } from "@storybook/svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import * as stories from "~stories/pages/room.stories";

const { OwnerLobby, PlayerLobby } = composeStories(stories);

describe("Room", () => {
  beforeEach(() => {
    vi.spyOn(HTMLMediaElement.prototype, "pause").mockImplementation(() => {});

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

  describe("Lobby", () => {
    test("renders owner lobby state", async () => {
      await OwnerLobby.run();

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
    });

    test("renders player lobby state", async () => {
      await PlayerLobby.run();

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
});
