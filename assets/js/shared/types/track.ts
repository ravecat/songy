/**
 * Musical track entity for the guessing game.
 * 
 * Contains essential information needed for gameplay including
 * unique identifier, title, artist, release year, and provider-specific metadata.
 */
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
  
  /** Provider-specific metadata (e.g., Spotify URI) */
  meta: Record<string, any>;
}
