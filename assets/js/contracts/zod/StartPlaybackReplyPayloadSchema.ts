/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const startPlaybackReplyPayloadSchema = z
  .object({
    status: z.literal("ok"),
    response: z.record(z.string(), z.unknown()),
  })
  .strict();
