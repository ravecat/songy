/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const emptyReply = z
  .object({
    status: z.literal("ok"),
    response: z.record(z.string(), z.unknown()),
  })
  .strict();
