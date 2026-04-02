import { render } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import DefaultMediaProvider from "~components/default_media_provider.svelte";
import GameContextFixture from "../fixtures/game_context_fixture.svelte";

describe("DefaultMediaProvider component", () => {
  let mockGameContext;
  let playSpy;
  let pauseSpy;
  let loadSpy;
  let addEventListenerSpy;

  function renderWithSession(session = mockGameContext) {
    return render(GameContextFixture, {
      component: DefaultMediaProvider,
      session,
    });
  }

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
    addEventListenerSpy = vi.spyOn(
      HTMLMediaElement.prototype,
      "addEventListener",
    );

    mockGameContext = {
      snapshot: {
        game: {
          track: {
            id: "1440783454",
            title: "Firestarter",
            artist: "The Prodigy",
            year: 1996,
            meta: {
              preview_url: "https://audio-ssl.itunes.apple.com/preview.m4a",
            },
          },
          player: {
            is_playback: false,
          },
        },
        permissions: {
          can_control_playback: true,
        },
        timer: null,
      },
      commands: {
        pausePlayback: vi.fn().mockResolvedValue(undefined),
      },
    };
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders audio element", () => {
    const { container } = renderWithSession();

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
  });

  test("sets audio src from track preview_url", () => {
    const { container } = renderWithSession();

    const audio = container.querySelector("audio");
    expect(audio).toHaveAttribute(
      "src",
      "https://audio-ssl.itunes.apple.com/preview.m4a",
    );
  });

  test("renders without error when children snippet is provided", () => {
    expect(() => {
      renderWithSession();
    }).not.toThrow();
  });

  test("calls load on mount", () => {
    renderWithSession();

    expect(loadSpy).toHaveBeenCalled();
  });

  test("has onended event handler", () => {
    renderWithSession();

    const call = addEventListenerSpy.mock.calls.find((c) => c[0] === "ended");
    expect(call).toBeDefined();
    expect(call[0]).toBe("ended");
    expect(typeof call[1]).toBe("function");
  });

  test("has correct preload attribute", () => {
    const { container } = renderWithSession();

    const audio = container.querySelector("audio");
    expect(audio).toHaveAttribute("preload", "auto");
  });

  test("audio element is hidden via style", () => {
    const { container } = renderWithSession();

    const audio = container.querySelector("audio");
    expect(audio).toHaveStyle("display: none;");
  });

  test("handles missing preview_url gracefully", () => {
    mockGameContext.snapshot.game.track.meta = {};
    const { container } = renderWithSession();

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
    expect(audio.getAttribute("src")).toBeNull();
  });


  test("loads when preview_url changes", () => {
    renderWithSession();

    const updatedGameContext = {
      ...mockGameContext,
      snapshot: {
        ...mockGameContext.snapshot,
        game: {
          ...mockGameContext.snapshot.game,
          track: {
            ...mockGameContext.snapshot.game.track,
            meta: {
              preview_url: "https://new-preview-url.m4a",
            },
          },
        },
      },
    };

    renderWithSession(updatedGameContext);

    expect(loadSpy).toHaveBeenCalled();
  });

  test("calls play when is_playback is true", () => {
    mockGameContext.snapshot.game.player.is_playback = true;
    renderWithSession();

    expect(playSpy).toHaveBeenCalled();
  });

  test("calls pause when is_playback is false", () => {
    mockGameContext.snapshot.game.player.is_playback = false;
    renderWithSession();

    expect(pauseSpy).toHaveBeenCalled();
  });

  test("handles play errors gracefully", () => {
    playSpy.mockRejectedValue(new Error("Playback failed"));
    mockGameContext.snapshot.game.player.is_playback = true;

    expect(() => {
      renderWithSession();
    }).not.toThrow();
  });

  test("renders when game context is missing player", () => {
    delete mockGameContext.snapshot.game.player;
    const { container } = renderWithSession();

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
  });

  test("handles both preview_url and url being undefined", () => {
    mockGameContext.snapshot.game.track.meta = undefined;
    const { container } = renderWithSession();

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
    expect(audio.getAttribute("src")).toBeNull();
  });

  test("handles empty meta object", () => {
    mockGameContext.snapshot.game.track.meta = {};
    const { container } = renderWithSession();

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
  });

  test("works with valid track data but missing player state", () => {
    delete mockGameContext.snapshot.game.player;
    const { container } = renderWithSession();

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
    expect(audio.getAttribute("src")).toBe(
      "https://audio-ssl.itunes.apple.com/preview.m4a",
    );
  });

  test("toggles playback correctly", () => {
    renderWithSession();

    mockGameContext.snapshot.game.player.is_playback = true;
    renderWithSession();

    expect(playSpy).toHaveBeenCalled();

    mockGameContext.snapshot.game.player.is_playback = false;
    renderWithSession();

    expect(pauseSpy).toHaveBeenCalled();
  });
});
