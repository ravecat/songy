/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const trackSchema = z
  .object({
    id: z.string(),
    title: z.string(),
    artist: z.string(),
    year: z.number().int(),
    cover_url: z.union([z.string(), z.null()]),
    meta: z
      .object({
        preview_url: z.string().optional(),
        uri: z.string().optional(),
      })
      .catchall(z.unknown()),
  })
  .strict()
  .describe("JSON-encoded `Songy.Core.Track`");
