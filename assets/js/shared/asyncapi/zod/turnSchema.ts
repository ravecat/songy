/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const turn = z
  .object({
    track: z
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
      .describe("Music track data")
      .optional(),
    assumptions: z
      .record(z.string(), z.number().int())
      .describe("Map of user_id to guessed position")
      .optional(),
  })
  .catchall(z.unknown())
  .describe("Current turn state");
