/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const permissions = z
  .object({
    can_start_game: z.boolean().optional(),
    can_start_playback: z.boolean().optional(),
    can_pause_playback: z.boolean().optional(),
    can_advance_turn: z.boolean().optional(),
    can_make_assumption: z.boolean().optional(),
  })
  .catchall(z.unknown())
  .describe(
    "Caller-specific permission flags computed by `Songy.Authorization`.\nAll boolean fields; missing key means `false`.\n",
  );
