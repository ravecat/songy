/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

/**
 * Current turn state
 */
export interface Turn {
  /**
   * Music track data
   */
  track?: {
    id?: string;
    name?: string;
    artist?: string;
    /**
     * Provider URI (e.g. Spotify track URI)
     */
    uri?: string;
    [k: string]: unknown;
  };
  /**
   * Map of user_id to guessed position
   */
  assumptions?: {
    [k: string]: number;
  };
  [k: string]: unknown;
}
