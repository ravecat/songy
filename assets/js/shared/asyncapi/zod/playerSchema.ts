/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const player = z
  .object({
    id: z.string().optional(),
    name: z.string().optional(),
    score: z.number().int().optional(),
  })
  .catchall(z.unknown())
  .describe("Player state within the game");
