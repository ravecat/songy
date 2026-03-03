/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const assumptionPayload = z.object({
  position: z
    .number()
    .int()
    .gte(0)
    .describe(
      "0-based index of the guessed track position in the ordered playlist. Must be a non-negative integer.\n",
    ),
});
