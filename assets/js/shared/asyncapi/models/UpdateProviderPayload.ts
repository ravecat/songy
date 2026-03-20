/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

/**
 * Partial Spotify provider patch accepted by `update_provider`. Unknown keys are ignored by the current provider struct update logic.
 *
 */
export interface UpdateProviderPayload {
  access_token?: string;
  refresh_token?: string;
  device_id?: string;
  [k: string]: unknown;
}
