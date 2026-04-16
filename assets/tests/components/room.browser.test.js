import Room from "~pages/room.svelte";
import { beforeEach, describe, expect, test, vi } from "vitest";
import { users } from "~fixtures/users";
import { render } from "../inertia";

describe("Room", () => {
  beforeEach(() => {
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    });
  });

  describe("screen", () => {
    test("renders owner lobby state from the room page", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-owner-lobby",
          qr: "<svg data-testid='room-qr'></svg>",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

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
      expect(document.body.querySelectorAll(".lobby-player")).toHaveLength(3);
    });

    test("renders player lobby state from the room page", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-player-lobby",
          scope: {
            user: users.bob,
            provider: null,
          },
        },
      });

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
      expect(document.body.querySelectorAll(".lobby-player")).toHaveLength(3);
    });
  });

  describe("lobby", () => {
    test("renders lobby structure with players list and share button", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-player-lobby",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      await expect
        .element(screen.getByRole("list", { name: "Lobby players" }))
        .toBeVisible();
      await expect
        .element(screen.getByRole("button", { name: "Copy share link" }))
        .toBeVisible();
      expect(document.body.querySelectorAll(".lobby-player")).toHaveLength(3);
    });

    test("displays all participants with avatars and names", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-player-lobby",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      for (const user of Object.values(users)) {
        await expect.element(screen.getByAltText(user.name)).toHaveAttribute(
          "src",
          user.avatar_url,
        );
        await expect.element(screen.getByText(user.name)).toBeVisible();
      }
    });

    test("shows crown badge for room owner", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-player-lobby",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      await expect
        .element(screen.getByRole("list", { name: "Lobby players" }))
        .toBeVisible();

      const players = Array.from(document.body.querySelectorAll(".lobby-player"));
      const ownerPlayer = players.find((player) =>
        player.textContent?.includes(users.alice.name)
      );

      expect(ownerPlayer).toBeDefined();
      expect(ownerPlayer?.querySelector(".lobby-player__badge")).not.toBeNull();
    });

    test("renders share button with the current room URL", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-player-lobby",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      await expect
        .element(screen.getByText(window.location.href))
        .toBeVisible();
    });

    test("renders QR svg when page props provide it", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-player-lobby",
          qr: "<svg data-testid='qr-svg'></svg>",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      await expect.element(screen.getByTestId("qr-svg")).toBeVisible();
    });

    test("copies URL to clipboard on share button click", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-player-lobby",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      await screen.getByRole("button", { name: "Copy share link" }).click();

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
        window.location.href,
      );
    });

    test("shows copied state after clicking share button", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-player-lobby",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      const shareButton = screen.getByRole("button", {
        name: "Copy share link",
      });

      await shareButton.click();

      await expect.element(screen.getByText("Copied!")).toBeVisible();
      await expect.element(shareButton).toBeDisabled();
    });

    test("handles empty participants list", async () => {
      const screen = render(Room, {
        props: {
          roomId: "room-empty-lobby",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });

      expect(screen.getByRole("list", { name: "Lobby players" })).toBeDefined();
      expect(document.body.querySelectorAll(".lobby-player")).toHaveLength(0);
    });
  });
});
