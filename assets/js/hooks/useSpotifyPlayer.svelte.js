/**
 * Hook for Spotify Web Playback SDK player management
 * @param {string} token - Spotify access token
 * @param {Object} options - Configuration options
 * @param {string} options.name - Device name (default: 'Web Playback SDK Player')
 * @param {number} options.volume - Initial volume 0-1 (default: 0.5)
 * @param {Object} [options.on] - Event handlers object
 * @returns {Object} Spotify Player instance
 */
export function useSpotifyPlayer(token, options = {}) {
  const { name = "Web Playback SDK Player", volume = 0.5, on = {} } = options;

  const eventCallbacks = {
    ready: (data) => console.log("Ready with Device ID", data.device_id),
    not_ready: (data) =>
      console.log("Device ID has gone offline", data.device_id),
    player_state_changed: (state) =>
      console.log("Player state changed:", state),
    autoplay_failed: () =>
      console.log("Autoplay is not allowed by the browser autoplay rules"),
    initialization_error: (error) =>
      console.error("Failed to initialize:", error.message),
    authentication_error: (error) =>
      console.error("Failed to authenticate:", error.message),
    account_error: (error) =>
      console.error("Failed to validate Spotify account:", error.message),
    playback_error: (error) =>
      console.error("Failed to perform playback:", error.message),
    ...on,
  };

  let player = $state(null);

  
  $effect(() => {
    if (!token) {
      if (player) {
        player.disconnect();
        player = null;
      }
      return;
    }

    if (window.Spotify?.Player) {
      initializePlayer();
    } else {
      const script = document.createElement("script");
      script.src = "https://sdk.scdn.co/spotify-player.js";
      script.async = true;

      script.onerror = () => {
        console.error("Failed to load Spotify SDK script");
      };

      document.body.appendChild(script);

      window.onSpotifyWebPlaybackSDKReady = () => {
        initializePlayer();
      };
    }

    function initializePlayer() {
      player = new window.Spotify.Player({
        name: name,
        getOAuthToken: (cb) => {
          cb(token);
        },
        volume: volume,
      });

      player.addListener("ready", eventCallbacks.ready);
      player.addListener("not_ready", eventCallbacks.not_ready);
      player.addListener(
        "player_state_changed",
        eventCallbacks.player_state_changed
      );
      player.addListener("autoplay_failed", eventCallbacks.autoplay_failed);
      player.addListener(
        "initialization_error",
        eventCallbacks.initialization_error
      );
      player.addListener(
        "authentication_error",
        eventCallbacks.authentication_error
      );
      player.addListener("account_error", eventCallbacks.account_error);
      player.addListener("playback_error", eventCallbacks.playback_error);

      player.connect();
    }

    return () => {
      if (player) {
        player.disconnect();
        player = null;
      }
    };
  });

  return {
    get player() {
      return player;
    },
    get togglePlay() {
      return () => player?.togglePlay();
    },
    get pause() {
      return () => player?.pause();
    },
    get resume() {
      return () => player?.resume();
    },
    get nextTrack() {
      return () => player?.nextTrack();
    },
    get previousTrack() {
      return () => player?.previousTrack();
    },
    get seek() {
      return (position_ms) => player?.seek(position_ms);
    },
    get getCurrentState() {
      return () => player?.getCurrentState();
    },
    get getVolume() {
      return () => player?.getVolume();
    },
    get setVolume() {
      return (volume) => player?.setVolume(volume);
    },
    get setName() {
      return (name) => player?.setName(name);
    },
    get activateElement() {
      return () => player?.activateElement();
    },
    get connect() {
      return () => player?.connect();
    },
    get disconnect() {
      return () => player?.disconnect();
    },
    get addListener() {
      return (event, callback) => player?.addListener(event, callback);
    },
    get removeListener() {
      return (event, callback) => player?.removeListener(event, callback);
    },
  };
}
