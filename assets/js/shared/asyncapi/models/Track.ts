/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

/**
 * Music track data
 */
export interface Track {
  id?: string;
  name?: string;
  artist?: string;
  /**
   * Provider URI (e.g. Spotify track URI)
   */
  uri?: string;
  [k: string]: unknown;
}
