/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const timerPayload = z
  .object({
    remaining: z
      .number()
      .int()
      .gte(0)
      .describe("Remaining time in whole seconds"),
  })
  .strict();
