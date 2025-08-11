/**
 * Music provider configuration and credentials.
 */

/**
 * Provider type for music services
 */
export type ProviderId = 'spotify';

/**
 * Spotify provider credentials and configuration.
 * 
 * Handles OAuth tokens and device identification for playback control.
 */
export interface SpotifyProvider {
  /** Token expiration timestamp */
  expires_at?: string;
  
  /** OAuth access token */
  access_token?: string;
  
  /** OAuth refresh token */
  refresh_token?: string;
  
  /** Spotify device ID for playback */
  device_id?: string;
}

/**
 * Music provider configuration with type and metadata.
 * 
 * Supports different music services through polymorphic structure.
 */
export interface Provider {
  /** Provider type identifier */
  id: ProviderId;
  
  /** Provider-specific configuration */
  meta?: SpotifyProvider;
}
