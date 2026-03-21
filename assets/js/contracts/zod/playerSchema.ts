/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const player = z
  .object({ is_playback: z.boolean() })
  .strict()
  .describe("JSON-encoded `Songy.Core.Player`");
