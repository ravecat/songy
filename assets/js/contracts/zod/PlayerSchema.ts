/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const playerSchema = z
  .object({ is_playback: z.boolean() })
  .strict()
  .describe("JSON-encoded player");
