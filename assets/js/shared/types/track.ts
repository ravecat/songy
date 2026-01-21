/**
 * Musical track entity for the guessing game.
 *
 * Contains essential information needed for gameplay including
 * unique identifier, title, artist, release year, and provider-specific metadata.
 */

/**
 * Provider-specific metadata for playback functionality.
 */
export type TrackMeta = {
  /** Audio preview URL (30-60 second clips, used by iTunes/Apple Music) */
  preview_url?: string;
  /** Platform-specific URI (e.g., spotify:track:xxx, used by Spotify) */
  uri?: string;
};

export interface Track {
  /** Unique track identifier */
  id: string;

  /** Song title */
  title: string;

  /** Artist name */
  artist: string;

  /** Release year (used for guessing) */
  year: number;

  /** Album cover image URL */
  cover_url?: string;

  /** Provider-specific metadata */
  meta: TrackMeta;
}
