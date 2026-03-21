/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const providerNotFoundReply = z
  .object({
    status: z.literal("error"),
    response: z.object({ reason: z.literal("provider_not_found") }).strict(),
  })
  .strict();
