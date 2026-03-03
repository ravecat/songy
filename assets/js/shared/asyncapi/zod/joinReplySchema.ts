/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const joinReply = z.union([
  z.object({
    status: z.literal("ok"),
    response: z.record(z.string(), z.unknown()),
  }),
  z.object({
    status: z.literal("error"),
    response: z.object({
      reason: z.string().describe('Error reason (e.g. "game_not_found")'),
    }),
  }),
]);
