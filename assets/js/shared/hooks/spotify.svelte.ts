/// <reference types="@types/spotify-web-playback-sdk" />

/**
 * Spotify Web Playback SDK events
 */
export enum SPOTIFY_EVENT {
  READY = "ready",
  NOT_READY = "not_ready",
  PLAYER_STATE_CHANGED = "player_state_changed",
  AUTOPLAY_FAILED = "autoplay_failed",
  INITIALIZATION_ERROR = "initialization_error",
  AUTHENTICATION_ERROR = "authentication_error",
  ACCOUNT_ERROR = "account_error",
  PLAYBACK_ERROR = "playback_error",
}

/**
 * Spotify event payloads mapping
 */
export interface SpotifyEventPayloads {
  [SPOTIFY_EVENT.READY]: Spotify.WebPlaybackInstance;
  [SPOTIFY_EVENT.NOT_READY]: Spotify.WebPlaybackInstance;
  [SPOTIFY_EVENT.PLAYER_STATE_CHANGED]: Spotify.PlaybackState | null;
  [SPOTIFY_EVENT.AUTOPLAY_FAILED]: void;
  [SPOTIFY_EVENT.INITIALIZATION_ERROR]: Spotify.Error;
  [SPOTIFY_EVENT.AUTHENTICATION_ERROR]: Spotify.Error;
  [SPOTIFY_EVENT.ACCOUNT_ERROR]: Spotify.Error;
  [SPOTIFY_EVENT.PLAYBACK_ERROR]: Spotify.Error;
}

export interface UseSpotifyPlayerOptions {
  /** Device name (default: 'Web Playback SDK Player') */
  name?: string;
  /** Function that provides fresh access token. Should call callback with token: (cb) => cb(token) */
  getOAuthToken?: (callback: (token: string) => void) => void;
  /** Initial volume 0-1 (default: 0.5) */
  volume?: number;
  /** Event handlers object for player events */
  on?: Partial<{
    [SPOTIFY_EVENT.READY]: (data: SpotifyEventPayloads[typeof SPOTIFY_EVENT.READY]) => void;
    [SPOTIFY_EVENT.NOT_READY]: (data: SpotifyEventPayloads[typeof SPOTIFY_EVENT.NOT_READY]) => void;
    [SPOTIFY_EVENT.PLAYER_STATE_CHANGED]: (state: SpotifyEventPayloads[typeof SPOTIFY_EVENT.PLAYER_STATE_CHANGED]) => void;
    [SPOTIFY_EVENT.AUTOPLAY_FAILED]: () => void;
    [SPOTIFY_EVENT.INITIALIZATION_ERROR]: (error: SpotifyEventPayloads[typeof SPOTIFY_EVENT.INITIALIZATION_ERROR]) => void;
    [SPOTIFY_EVENT.AUTHENTICATION_ERROR]: (error: SpotifyEventPayloads[typeof SPOTIFY_EVENT.AUTHENTICATION_ERROR]) => void;
    [SPOTIFY_EVENT.ACCOUNT_ERROR]: (error: SpotifyEventPayloads[typeof SPOTIFY_EVENT.ACCOUNT_ERROR]) => void;
    [SPOTIFY_EVENT.PLAYBACK_ERROR]: (error: SpotifyEventPayloads[typeof SPOTIFY_EVENT.PLAYBACK_ERROR]) => void;
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
      cb("");
    },
    volume = 0.5,
    on = {},
  } = options;

  const eventCallbacks: Required<UseSpotifyPlayerOptions['on']> = {
    [SPOTIFY_EVENT.READY]: () => { },
    [SPOTIFY_EVENT.NOT_READY]: () => { },
    [SPOTIFY_EVENT.PLAYER_STATE_CHANGED]: () => { },
    [SPOTIFY_EVENT.AUTOPLAY_FAILED]: () => { },
    [SPOTIFY_EVENT.INITIALIZATION_ERROR]: () => { },
    [SPOTIFY_EVENT.AUTHENTICATION_ERROR]: () => { },
    [SPOTIFY_EVENT.ACCOUNT_ERROR]: () => { },
    [SPOTIFY_EVENT.PLAYBACK_ERROR]: () => { },
    ...on,
  };

  let player = $state<Spotify.Player | null>(null);
  let instancePlayer: Spotify.Player | null = null;

  $effect(() => {
    const script = document.createElement("script");
    script.src = "https://sdk.scdn.co/spotify-player.js";
    script.async = true;

    script.onerror = () => {
      // Failed to load Spotify SDK script
    };

    document.body.appendChild(script);

    window.onSpotifyWebPlaybackSDKReady = () => {
      instancePlayer = new window.Spotify.Player({
        name: name,
        getOAuthToken: getOAuthToken,
        volume: volume,
      });

      player = instancePlayer;

      instancePlayer.addListener(SPOTIFY_EVENT.READY, eventCallbacks[SPOTIFY_EVENT.READY]);
      instancePlayer.addListener(SPOTIFY_EVENT.NOT_READY, eventCallbacks[SPOTIFY_EVENT.NOT_READY]);
      instancePlayer.addListener(
        SPOTIFY_EVENT.PLAYER_STATE_CHANGED,
        eventCallbacks[SPOTIFY_EVENT.PLAYER_STATE_CHANGED]
      );
      instancePlayer.addListener(
        SPOTIFY_EVENT.AUTOPLAY_FAILED,
        eventCallbacks[SPOTIFY_EVENT.AUTOPLAY_FAILED]
      );
      instancePlayer.addListener(
        SPOTIFY_EVENT.INITIALIZATION_ERROR,
        eventCallbacks[SPOTIFY_EVENT.INITIALIZATION_ERROR]
      );
      instancePlayer.addListener(
        SPOTIFY_EVENT.AUTHENTICATION_ERROR,
        eventCallbacks[SPOTIFY_EVENT.AUTHENTICATION_ERROR]
      );
      instancePlayer.addListener(SPOTIFY_EVENT.ACCOUNT_ERROR, eventCallbacks[SPOTIFY_EVENT.ACCOUNT_ERROR]);
      instancePlayer.addListener(
        SPOTIFY_EVENT.PLAYBACK_ERROR,
        eventCallbacks[SPOTIFY_EVENT.PLAYBACK_ERROR]
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
