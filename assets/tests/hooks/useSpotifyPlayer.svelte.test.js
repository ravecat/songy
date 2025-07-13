import { expect, test, vi, beforeEach, afterEach } from "vitest";
import { flushSync } from "svelte";
import { useSpotifyPlayer } from "@hooks/useSpotifyPlayer.svelte";

describe("useSpotifyPlayer", () => {
  beforeEach(() => {
    vi.stubGlobal("Spotify", {
      Player: vi.fn().mockImplementation(() => ({
        addListener: vi.fn().mockReturnThis(),
        connect: vi.fn().mockReturnThis(),
        disconnect: vi.fn().mockReturnThis(),
        togglePlay: vi.fn().mockReturnThis(),
        pause: vi.fn().mockReturnThis(),
        resume: vi.fn().mockReturnThis(),
        nextTrack: vi.fn().mockReturnThis(),
        previousTrack: vi.fn().mockReturnThis(),
        seek: vi.fn().mockReturnThis(),
        getCurrentState: vi.fn().mockReturnThis(),
        getVolume: vi.fn().mockReturnThis(),
        setVolume: vi.fn().mockReturnThis(),
        setName: vi.fn().mockReturnThis(),
        activateElement: vi.fn().mockReturnThis(),
        removeListener: vi.fn().mockReturnThis(),
      })),
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
    vi.unstubAllGlobals();
  });

  test("should initialize Spotify Player SDK", () => {
    const cleanup = $effect.root(() => {
      useSpotifyPlayer({
        name: "test-player",
        getOAuthToken: () => {},
        on: {},
      });

      flushSync();

      expect(window.onSpotifyWebPlaybackSDKReady).toBeDefined();
      expect(typeof window.onSpotifyWebPlaybackSDKReady).toBe("function");
    });

    cleanup();
  });

  test("should create player with correct arguments", () => {
    const cleanup = $effect.root(() => {
      const returnedValue = useSpotifyPlayer({
        name: "test-player",
        getOAuthToken: () => {},
        on: {},
      });

      flushSync();

      window.onSpotifyWebPlaybackSDKReady();

      expect(window.Spotify.Player).toHaveBeenCalledWith({
        name: "test-player",
        getOAuthToken: expect.any(Function),
        volume: 0.5,
      });

      const player = window.Spotify.Player.mock.results[0].value;

      expect(player.connect).toHaveBeenCalled();
      expect(typeof player.togglePlay).toBe("function");
      expect(typeof player.pause).toBe("function");
      expect(typeof player.resume).toBe("function");
      expect(returnedValue.player).toStrictEqual(player);
    });

    cleanup();
  });

  test("should handle player events", () => {
    const cleanup = $effect.root(() => {
      useSpotifyPlayer({
        name: "test-player",
        getOAuthToken: () => {},
        on: {},
      });

      flushSync();

      window.onSpotifyWebPlaybackSDKReady();

      const player = window.Spotify.Player.mock.results[0].value;

      expect(player.addListener).toHaveBeenCalledWith(
        "ready",
        expect.any(Function)
      );
      expect(player.addListener).toHaveBeenCalledWith(
        "not_ready",
        expect.any(Function)
      );
      expect(player.addListener).toHaveBeenCalledWith(
        "player_state_changed",
        expect.any(Function)
      );
      expect(player.addListener).toHaveBeenCalledWith(
        "autoplay_failed",
        expect.any(Function)
      );
      expect(player.addListener).toHaveBeenCalledWith(
        "initialization_error",
        expect.any(Function)
      );
      expect(player.addListener).toHaveBeenCalledWith(
        "authentication_error",
        expect.any(Function)
      );
      expect(player.addListener).toHaveBeenCalledWith(
        "account_error",
        expect.any(Function)
      );
      expect(player.addListener).toHaveBeenCalledWith(
        "playback_error",
        expect.any(Function)
      );
    });

    cleanup();
  });

  test("should disconnect player on cleanup", () => {
    const cleanup = $effect.root(() => {
      let player = useSpotifyPlayer({
        name: "test-player",
        getOAuthToken: () => {},
        on: {},
      });

      flushSync();

      window.onSpotifyWebPlaybackSDKReady();

      expect(player.player).toStrictEqual(
        window.Spotify.Player.mock.results[0].value
      );
    });

    cleanup();

    expect(
      window.Spotify.Player.mock.results[0].value.disconnect
    ).toHaveBeenCalled();
  });
});
