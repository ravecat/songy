/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

/**
 * Partial update for the caller's provider record in ETS. All known Spotify provider fields are accepted.
 *
 */
export interface UpdateProviderPayload {
  /**
   * Refreshed Spotify OAuth access token
   */
  access_token?: string;
  /**
   * Spotify OAuth refresh token
   */
  refresh_token?: string;
  /**
   * Spotify Connect device ID for playback
   */
  device_id?: string;
  /**
   * Token expiry as Unix timestamp (seconds)
   */
  expires_at?: number;
  [k: string]: unknown;
}
