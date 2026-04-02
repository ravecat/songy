import { page } from "vitest/browser";
import { createRawSnippet } from "svelte";
import { writable } from "svelte/store";
import { beforeEach, describe, expect, test, vi } from "vitest";

vi.mock("~/stores/game", () => ({
  createGameSession: vi.fn(),
}));

import GameProvider from "~components/game_provider.svelte";
import { createGameSession } from "~/stores/game";

describe("GameProvider", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test("renders children when the session is ready", async () => {
    vi.mocked(createGameSession).mockReturnValue(writable({
      snapshot: { ready: true },
      status: "ready",
      error: null,
    }));

    const screen = page.render(GameProvider, {
      topic: "room:test-room",
      children: createRawSnippet(() => ({
        render: () => "<span>game-provider-child</span>",
      })),
    });

    await expect
      .element(screen.getByText("game-provider-child"))
      .toBeInTheDocument();
  });

  test("renders loader while the session is loading", async () => {
    vi.mocked(createGameSession).mockReturnValue(writable({
      snapshot: null,
      status: "loading",
      error: null,
    }));

    const screen = page.render(GameProvider, {
      topic: "room:test-room",
    });

    await expect
      .element(screen.getByRole("status", { name: "loading" }))
      .toBeVisible();
    await expect.element(screen.getByRole("alert")).not.toBeInTheDocument();
  });

  test("switches from loader to children when the session becomes ready", async () => {
    const session = writable({
      snapshot: null,
      status: "loading",
      error: null,
    });

    vi.mocked(createGameSession).mockReturnValue(session);

    const screen = page.render(GameProvider, {
      topic: "room:test-room",
      children: createRawSnippet(() => ({
        render: () => "<span>game-provider-child</span>",
      })),
    });

    await expect
      .element(screen.getByRole("status", { name: "loading" }))
      .toBeVisible();

    session.set({
      snapshot: { ready: true },
      status: "ready",
      error: null,
    });

    await expect
      .element(screen.getByText("game-provider-child"))
      .toBeInTheDocument();
  });

  test("renders connect errors with the server reason", async () => {
    vi.mocked(createGameSession).mockReturnValue(writable({
      snapshot: null,
      status: "failed",
      error: {
        kind: "connect_error",
        cause: {
          reason: "game_not_found",
        },
      },
    }));

    const screen = page.render(GameProvider, {
      topic: "room:test-room",
    });

    await expect.element(screen.getByRole("alert")).toBeVisible();
    await expect.element(screen.getByText("Room unavailable")).toBeVisible();
    await expect
      .element(screen.getByText("Reason: game_not_found"))
      .toBeVisible();
    await expect
      .element(screen.getByRole("link", { name: "Back home" }))
      .toHaveAttribute("href", "/");
  });

  test("renders a generic message for non-connect failures", async () => {
    vi.mocked(createGameSession).mockReturnValue(
      writable({
        snapshot: null,
        status: "failed",
        error: {
          kind: "transport_close",
        },
      }),
    );

    const screen = page.render(GameProvider, {
      topic: "room:test-room",
    });

    await expect.element(screen.getByRole("alert")).toBeVisible();
    await expect
      .element(screen.getByText("Failed to load game state."))
      .toBeVisible();
  });
});
