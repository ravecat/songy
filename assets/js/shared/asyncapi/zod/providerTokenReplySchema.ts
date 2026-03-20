/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const providerTokenReply = z
  .object({
    status: z.literal("ok"),
    response: z.object({ token: z.string() }).strict(),
  })
  .strict();
