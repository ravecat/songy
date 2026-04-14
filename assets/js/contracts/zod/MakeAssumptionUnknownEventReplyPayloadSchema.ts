/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const makeAssumptionUnknownEventReplyPayloadSchema = z
  .object({
    status: z.literal("error"),
    response: z
      .object({ reason: z.literal("unknown_event"), event: z.string() })
      .strict(),
  })
  .strict();
