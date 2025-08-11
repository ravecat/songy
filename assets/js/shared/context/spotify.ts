import { getContext } from "svelte";
import type { UseSpotifyPlayerReturn } from "@hooks/useSpotifyPlayer.svelte";

/**
 * Spotify player context interface
 */
export interface SpotifyContext {
  /** Spotify player instance and control methods from useSpotifyPlayer hook */
  spotifyPlayer: UseSpotifyPlayerReturn;
}

/**
 * Get the Spotify player context from Svelte's context system
 * 
 * Must be called within a component that has a SpotifyPlayerProvider component as a parent.
 * Provides access to the Spotify Web Playback SDK player instance and all player control methods.
 * 
 * @returns Spotify context containing player instance and control methods
 * @throws Error if called outside of a SpotifyPlayerProvider component
 */
export function getSpotifyContext(): SpotifyContext {
  const context = getContext<SpotifyContext>("spotify");

  if (!context) {
    throw new Error(
      "getSpotifyContext() must be called within a SpotifyPlayerProvider component"
    );
  }

  return context;
}
