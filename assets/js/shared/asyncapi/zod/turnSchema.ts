/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const turn = z
  .object({
    phase: z.enum(["waiting", "ready", "challenging", "results"]),
    assumptions: z
      .record(z.string(), z.string())
      .describe(
        "Map keyed by JSON stringified zero-based positions. Values are user ids.\n",
      ),
    winner_id: z.union([z.string(), z.null()]),
  })
  .strict()
  .describe("JSON-encoded `Songy.Core.Turn`");
