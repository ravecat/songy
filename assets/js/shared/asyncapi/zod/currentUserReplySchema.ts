/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const currentUserReply = z
  .object({
    status: z.literal("ok"),
    response: z
      .object({ uuid: z.string(), name: z.string(), avatar_url: z.string() })
      .strict()
      .describe("JSON-encoded `Songy.Core.User`"),
  })
  .strict();
