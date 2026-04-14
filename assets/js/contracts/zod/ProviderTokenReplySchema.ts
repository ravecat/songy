/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const providerTokenReplySchema = z
  .object({
    status: z.literal("ok"),
    response: z.object({ token: z.string() }).strict(),
  })
  .strict();
