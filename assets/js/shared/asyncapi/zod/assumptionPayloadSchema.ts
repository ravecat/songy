/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const assumptionPayload = z
  .object({
    position: z
      .number()
      .int()
      .gte(0)
      .describe(
        "Zero-based insertion position in the active player's timeline",
      ),
  })
  .strict();
