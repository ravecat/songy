/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const userSchema = z
  .object({
    uuid: z.string().regex(new RegExp("^[0-9a-f]{32}$")),
    name: z.string(),
    avatar_url: z.string().url(),
  })
  .strict()
  .describe("JSON-encoded `Songy.Core.User`");
