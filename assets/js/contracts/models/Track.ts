/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

/**
 * JSON-encoded `Songy.Core.Track`
 */
export interface Track {
  id: string;
  title: string;
  artist: string;
  year: number;
  cover_url: string | null;
  meta: {
    preview_url?: string;
    uri?: string;
    [k: string]: unknown;
  };
}
