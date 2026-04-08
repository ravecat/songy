import Room from "~pages/room.svelte";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { users } from "~fixtures/users";
import { render } from "../inertia";

function getAudio() {
  return document.body.querySelector("audio");
}

describe("DefaultMediaProvider component", () => {
  let playSpy;
  let pauseSpy;
  let loadSpy;

  beforeEach(() => {
    playSpy = vi
      .spyOn(HTMLMediaElement.prototype, "play")
      .mockResolvedValue(undefined);
    pauseSpy = vi
      .spyOn(HTMLMediaElement.prototype, "pause")
      .mockImplementation(() => {});
    loadSpy = vi
      .spyOn(HTMLMediaElement.prototype, "load")
      .mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders audio element", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-media",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Lobby players" }))
      .toBeVisible();

    expect(getAudio()).not.toBeNull();
  });

  test("sets audio src from track preview_url", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-media",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Lobby players" }))
      .toBeVisible();

    expect(getAudio()).toHaveAttribute(
      "src",
      "https://audio-ssl.itunes.apple.com/preview.m4a",
    );
  });

  test("calls load on mount", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-media",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Lobby players" }))
      .toBeVisible();

    await vi.waitFor(() => {
      expect(loadSpy).toHaveBeenCalled();
    });
  });

  test("pauses playback when the preview ends", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-media-playing",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("button", { name: "Pause track" }))
      .toBeVisible();

    getAudio().dispatchEvent(new Event("ended"));

    await expect
      .element(screen.getByRole("button", { name: "Play track" }))
      .toBeVisible();
  });

  test("has correct preload attribute", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-media",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Lobby players" }))
      .toBeVisible();

    expect(getAudio()).toHaveAttribute("preload", "auto");
  });

  test("audio element is hidden via style", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-media",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Lobby players" }))
      .toBeVisible();

    expect(getAudio()).toHaveStyle("display: none;");
  });

  test("handles missing preview_url gracefully", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-media-no-preview",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Lobby players" }))
      .toBeVisible();

    expect(getAudio()).not.toBeNull();
    expect(getAudio().getAttribute("src")).toBeNull();
  });

  test("calls play when is_playback is true", async () => {
    render(Room, {
      props: {
        roomId: "room-media-playing",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await vi.waitFor(() => {
      expect(playSpy).toHaveBeenCalled();
    });
  });

  test("calls pause when is_playback is false", async () => {
    render(Room, {
      props: {
        roomId: "room-media",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await vi.waitFor(() => {
      expect(pauseSpy).toHaveBeenCalled();
    });
  });

  test("handles play errors gracefully", () => {
    playSpy.mockRejectedValue(new Error("Playback failed"));

    expect(() => {
      render(Room, {
        props: {
          roomId: "room-media-playing",
          scope: {
            user: users.alice,
            provider: null,
          },
        },
      });
    }).not.toThrow();
  });

  test("renders when player state is missing", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-media-no-player",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Lobby players" }))
      .toBeVisible();

    expect(getAudio()).not.toBeNull();
  });

  test("handles undefined track meta gracefully", async () => {
    const screen = render(Room, {
      props: {
        roomId: "room-media-no-meta",
        scope: {
          user: users.alice,
          provider: null,
        },
      },
    });

    await expect
      .element(screen.getByRole("list", { name: "Lobby players" }))
      .toBeVisible();

    expect(getAudio()).not.toBeNull();
    expect(getAudio().getAttribute("src")).toBeNull();
  });

});
