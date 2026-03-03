/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

/**
 * Full game state and caller's permissions
 */
export interface StatePayload {
  /**
   * Game struct serialized from `Songy.Core.Game`. All fields are
   * Jason-encoded. The `state` field is the GenStatem FSM state name.
   *
   */
  game: {
    /**
     * Room ID (unique_names_generator slug)
     */
    id?: string;
    /**
     * Current FSM state
     */
    state?:
      | "lobby"
      | "playing"
      | "turn"
      | "challenging"
      | "scoring"
      | "finished";
    /**
     * User ID of the room creator
     */
    host_id?: string;
    players?: {
      id?: string;
      name?: string;
      score?: number;
      [k: string]: unknown;
    }[];
    turn?: {
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
    } | null;
    tracks?: {
      id?: string;
      name?: string;
      artist?: string;
      /**
       * Provider URI (e.g. Spotify track URI)
       */
      uri?: string;
      [k: string]: unknown;
    }[];
    [k: string]: unknown;
  };
  /**
   * Caller-specific permission flags computed by `Songy.Authorization`.
   * All boolean fields; missing key means `false`.
   *
   */
  permissions: {
    can_start_game?: boolean;
    can_start_playback?: boolean;
    can_pause_playback?: boolean;
    can_advance_turn?: boolean;
    can_make_assumption?: boolean;
    [k: string]: unknown;
  };
}
