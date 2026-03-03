/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const timerPayload = z
  .object({
    remaining: z.number().int().describe("Remaining time in milliseconds"),
  })
  .describe("Countdown timer tick");
