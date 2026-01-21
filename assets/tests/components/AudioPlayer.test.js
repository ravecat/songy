import { render } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import * as GameContext from "~components/GameChannel.svelte";
import AudioPlayer from "~components/AudioPlayer.svelte";

describe("AudioPlayer component", () => {
  let mockGameContext;
  let getGameContextSpy;
  let playSpy;
  let pauseSpy;
  let loadSpy;
  let addEventListenerSpy;

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
      channel: {
        push: vi.fn().mockReturnValue({
          receive: vi.fn().mockReturnThis(),
        }),
      },
      permissions: {
        can_control_playback: true,
      },
    };

    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders audio element", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AudioPlayer);

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
  });

  test("sets audio src from track preview_url", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AudioPlayer);

    const audio = container.querySelector("audio");
    expect(audio).toHaveAttribute(
      "src",
      "https://audio-ssl.itunes.apple.com/preview.m4a",
    );
  });

  test("renders without error when children snippet is provided", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    expect(() => {
      render(AudioPlayer);
    }).not.toThrow();
  });

  test("calls load on mount", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(AudioPlayer);

    expect(loadSpy).toHaveBeenCalled();
  });

  test("has onended event handler", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(AudioPlayer);

    const call = addEventListenerSpy.mock.calls.find((c) => c[0] === "ended");
    expect(call).toBeDefined();
    expect(call[0]).toBe("ended");
    expect(typeof call[1]).toBe("function");
  });

  test("has correct preload attribute", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AudioPlayer);

    const audio = container.querySelector("audio");
    expect(audio).toHaveAttribute("preload", "auto");
  });

  test("audio element is hidden via style", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AudioPlayer);

    const audio = container.querySelector("audio");
    expect(audio).toHaveStyle("display: none;");
  });

  test("handles missing preview_url gracefully", () => {
    mockGameContext.game.track.meta = {};

    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AudioPlayer);

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
    expect(audio.getAttribute("src")).toBeNull();
  });

  test("uses url fallback when preview_url is not available", () => {
    mockGameContext.game.track.meta = {
      url: "https://fallback-url.m4a",
    };
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AudioPlayer);

    const audio = container.querySelector("audio");
    expect(audio).toHaveAttribute("src", "https://fallback-url.m4a");
  });

  test("loads when preview_url changes", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(AudioPlayer);

    const updatedGameContext = {
      ...mockGameContext,
      game: {
        ...mockGameContext.game,
        track: {
          ...mockGameContext.game.track,
          meta: {
            preview_url: "https://new-preview-url.m4a",
          },
        },
      },
    };

    getGameContextSpy.mockReturnValue(updatedGameContext);
    render(AudioPlayer);

    expect(loadSpy).toHaveBeenCalled();
  });

  test("calls play when is_playback is true", () => {
    mockGameContext.game.player.is_playback = true;
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(AudioPlayer);

    expect(playSpy).toHaveBeenCalled();
  });

  test("calls pause when is_playback is false", () => {
    mockGameContext.game.player.is_playback = false;
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(AudioPlayer);

    expect(pauseSpy).toHaveBeenCalled();
  });

  test("handles play errors gracefully", () => {
    playSpy.mockRejectedValue(new Error("Playback failed"));
    getGameContextSpy.mockReturnValue(mockGameContext);
    mockGameContext.game.player.is_playback = true;

    expect(() => {
      render(AudioPlayer);
    }).not.toThrow();
  });

  test("renders when game context is missing player", () => {
    delete mockGameContext.game.player;
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AudioPlayer);

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
  });

  test("handles both preview_url and url being undefined", () => {
    mockGameContext.game.track.meta = undefined;
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AudioPlayer);

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
    expect(audio.getAttribute("src")).toBeNull();
  });

  test("handles empty meta object", () => {
    mockGameContext.game.track.meta = {};
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AudioPlayer);

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
  });

  test("works with valid track data but missing player state", () => {
    delete mockGameContext.game.player;
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AudioPlayer);

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
    expect(audio.getAttribute("src")).toBe(
      "https://audio-ssl.itunes.apple.com/preview.m4a",
    );
  });

  test("toggles playback correctly", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(AudioPlayer);

    mockGameContext.game.player.is_playback = true;
    getGameContextSpy.mockReturnValue(mockGameContext);
    render(AudioPlayer);

    expect(playSpy).toHaveBeenCalled();

    mockGameContext.game.player.is_playback = false;
    getGameContextSpy.mockReturnValue(mockGameContext);
    render(AudioPlayer);

    expect(pauseSpy).toHaveBeenCalled();
  });
});
