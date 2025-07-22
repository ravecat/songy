import { getContext } from "svelte";

export function getSpotifyContext() {
  const context = getContext("spotify-player");

  if (!context) {
    throw new Error(
      "getSpotifyContext() must be called within a SpotifyPlayerProvider component"
    );
  }

  return context;
}
