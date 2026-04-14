/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const userSchema = z
  .object({ uuid: z.string(), name: z.string(), avatar_url: z.string() })
  .strict()
  .describe("JSON-encoded `Songy.Core.User`");
