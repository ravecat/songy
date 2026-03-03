/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const updateProviderPayload = z
  .object({
    access_token: z
      .string()
      .describe("Refreshed Spotify OAuth access token")
      .optional(),
    refresh_token: z
      .string()
      .describe("Spotify OAuth refresh token")
      .optional(),
    device_id: z
      .string()
      .describe("Spotify Connect device ID for playback")
      .optional(),
    expires_at: z
      .number()
      .int()
      .describe("Token expiry as Unix timestamp (seconds)")
      .optional(),
  })
  .catchall(z.unknown())
  .describe(
    "Partial update for the caller's provider record in ETS. All known Spotify provider fields are accepted.\n",
  );
