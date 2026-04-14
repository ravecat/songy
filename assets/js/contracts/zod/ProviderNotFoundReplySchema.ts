/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const providerNotFoundReplySchema = z
  .object({
    status: z.literal("error"),
    response: z.object({ reason: z.literal("provider_not_found") }).strict(),
  })
  .strict();
