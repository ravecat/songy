/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const updateProviderPayload = z
  .object({
    access_token: z.string().optional(),
    refresh_token: z.string().optional(),
    device_id: z.string().optional(),
  })
  .catchall(z.unknown())
  .describe(
    "Partial Spotify provider patch accepted by `update_provider`. Unknown keys are ignored by the current provider struct update logic.\n",
  );
