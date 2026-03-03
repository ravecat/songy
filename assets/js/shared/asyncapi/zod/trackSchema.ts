/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const track = z
  .object({
    id: z.string().optional(),
    name: z.string().optional(),
    artist: z.string().optional(),
    uri: z
      .string()
      .describe("Provider URI (e.g. Spotify track URI)")
      .optional(),
  })
  .catchall(z.unknown())
  .describe("Music track data");
