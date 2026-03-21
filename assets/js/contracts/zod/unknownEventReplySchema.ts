/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const unknownEventReply = z
  .object({
    status: z.literal("error"),
    response: z
      .object({ reason: z.literal("unknown_event"), event: z.string() })
      .strict(),
  })
  .strict();
