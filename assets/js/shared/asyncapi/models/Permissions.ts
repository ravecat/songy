/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

/**
 * Caller-specific permission flags computed by `Songy.Authorization`.
 * All boolean fields; missing key means `false`.
 *
 */
export interface Permissions {
  can_start_game?: boolean;
  can_start_playback?: boolean;
  can_pause_playback?: boolean;
  can_advance_turn?: boolean;
  can_make_assumption?: boolean;
  [k: string]: unknown;
}
