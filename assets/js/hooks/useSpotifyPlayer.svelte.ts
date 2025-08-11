/// <reference types="@types/spotify-web-playback-sdk" />

export interface UseSpotifyPlayerOptions {
  /** Device name (default: 'Web Playback SDK Player') */
  name?: string;
  /** Function that provides fresh access token. Should call callback with token: (cb) => cb(token) */
  getOAuthToken?: (callback: (token: string) => void) => void;
  /** Initial volume 0-1 (default: 0.5) */
  volume?: number;
  /** Event handlers object for player events */
  on?: Partial<{
    ready: (data: Spotify.WebPlaybackInstance) => void;
    not_ready: (data: Spotify.WebPlaybackInstance) => void;
    player_state_changed: (state: Spotify.PlaybackState | null) => void;
    autoplay_failed: () => void;
    initialization_error: (error: Spotify.Error) => void;
    authentication_error: (error: Spotify.Error) => void;
    account_error: (error: Spotify.Error) => void;
    playback_error: (error: Spotify.Error) => void;
  }>;
}

export interface UseSpotifyPlayerReturn {
  readonly togglePlay: Spotify.Player['togglePlay'];
  readonly pause: Spotify.Player['pause'];
  readonly resume: Spotify.Player['resume'];
  readonly nextTrack: Spotify.Player['nextTrack'];
  readonly previousTrack: Spotify.Player['previousTrack'];
  readonly seek: Spotify.Player['seek'];
  readonly getCurrentState: Spotify.Player['getCurrentState'];
  readonly getVolume: Spotify.Player['getVolume'];
  readonly setVolume: Spotify.Player['setVolume'];
  readonly setName: Spotify.Player['setName'];
  readonly activateElement: Spotify.Player['activateElement'];
  readonly connect: Spotify.Player['connect'];
  readonly disconnect: Spotify.Player['disconnect'];
  readonly addListener: Spotify.Player['addListener'] | null;
  readonly removeListener: Spotify.Player['removeListener'] | null;
}

/**
 * Hook for Spotify Web Playback SDK player management
 * @param options - Configuration options
 * @returns Spotify Player instance and control methods
 */
export function useSpotifyPlayer(options: UseSpotifyPlayerOptions = {}): UseSpotifyPlayerReturn {
  const {
    name = "Web Playback SDK Player",
    getOAuthToken = (cb: (token: string) => void) => {
      console.warn("getOAuthToken not provided, player will not work");
      cb("");
    },
    volume = 0.5,
    on = {},
  } = options;

  const eventCallbacks: Required<UseSpotifyPlayerOptions['on']> = {
    ready: (data: Spotify.WebPlaybackInstance) => console.log("Ready with Device ID", data.device_id),
    not_ready: (data: Spotify.WebPlaybackInstance) =>
      console.log("Device ID has gone offline", data.device_id),
    player_state_changed: () => { },
    autoplay_failed: () =>
      console.log("Autoplay is not allowed by the browser autoplay rules"),
    initialization_error: (error: Spotify.Error) =>
      console.error("Failed to initialize:", error.message),
    authentication_error: (error: Spotify.Error) =>
      console.error("Failed to authenticate:", error.message),
    account_error: (error: Spotify.Error) =>
      console.error("Failed to validate Spotify account:", error.message),
    playback_error: (error: Spotify.Error) =>
      console.error("Failed to perform playback:", error.message),
    ...on,
  };

  let player = $state<Spotify.Player | null>(null);
  let instancePlayer: Spotify.Player | null = null;

  $effect(() => {
    const script = document.createElement("script");
    script.src = "https://sdk.scdn.co/spotify-player.js";
    script.async = true;

    script.onerror = () => {
      console.error("Failed to load Spotify SDK script");
    };

    document.body.appendChild(script);

    window.onSpotifyWebPlaybackSDKReady = () => {
      instancePlayer = new window.Spotify.Player({
        name: name,
        getOAuthToken: getOAuthToken,
        volume: volume,
      });

      player = instancePlayer;

      instancePlayer.addListener("ready", eventCallbacks.ready);
      instancePlayer.addListener("not_ready", eventCallbacks.not_ready);
      instancePlayer.addListener(
        "player_state_changed",
        eventCallbacks.player_state_changed
      );
      instancePlayer.addListener(
        "autoplay_failed",
        eventCallbacks.autoplay_failed
      );
      instancePlayer.addListener(
        "initialization_error",
        eventCallbacks.initialization_error
      );
      instancePlayer.addListener(
        "authentication_error",
        eventCallbacks.authentication_error
      );
      instancePlayer.addListener("account_error", eventCallbacks.account_error);
      instancePlayer.addListener(
        "playback_error",
        eventCallbacks.playback_error
      );

      instancePlayer.connect();
    };

    return () => {
      instancePlayer?.disconnect();
    };
  });

  return {
    get togglePlay(): () => Promise<void> {
      return () => player?.togglePlay() ?? Promise.reject(new Error("Player not initialized"));
    },
    get pause(): () => Promise<void> {
      return () => player?.pause() ?? Promise.reject(new Error("Player not initialized"));
    },
    get resume(): () => Promise<void> {
      return () => player?.resume() ?? Promise.reject(new Error("Player not initialized"));
    },
    get nextTrack(): () => Promise<void> {
      return () => player?.nextTrack() ?? Promise.reject(new Error("Player not initialized"));
    },
    get previousTrack(): () => Promise<void> {
      return () => player?.previousTrack() ?? Promise.reject(new Error("Player not initialized"));
    },
    get seek(): (position_ms: number) => Promise<void> {
      return (position_ms: number) => player?.seek(position_ms) ?? Promise.reject(new Error("Player not initialized"));
    },
    get getCurrentState(): () => Promise<Spotify.PlaybackState | null> {
      return () => player?.getCurrentState() ?? Promise.reject(new Error("Player not initialized"));
    },
    get getVolume(): () => Promise<number> {
      return () => player?.getVolume() ?? Promise.reject(new Error("Player not initialized"));
    },
    get setVolume(): (volume: number) => Promise<void> {
      return (volume: number) => player?.setVolume(volume) ?? Promise.reject(new Error("Player not initialized"));
    },
    get setName(): (name: string) => Promise<void> {
      return (name: string) => player?.setName(name) ?? Promise.reject(new Error("Player not initialized"));
    },
    get activateElement(): () => Promise<void> {
      return () => player?.activateElement() ?? Promise.reject(new Error("Player not initialized"));
    },
    get connect(): () => Promise<boolean> {
      return () => player?.connect() ?? Promise.reject(new Error("Player not initialized"));
    },
    get disconnect(): () => void {
      return () => player?.disconnect() ?? (() => { throw new Error("Player not initialized"); })();
    },
    get addListener(): Spotify.AddListenerFn | null {
      return player?.addListener ?? null;
    },
    get removeListener(): ((
      event: "ready" | "not_ready" | "player_state_changed" | Spotify.ErrorTypes,
      cb?: Spotify.ErrorListener | Spotify.PlaybackInstanceListener | Spotify.PlaybackStateListener,
    ) => void) | null {
      return player?.removeListener ?? null;
    },
  };
}
