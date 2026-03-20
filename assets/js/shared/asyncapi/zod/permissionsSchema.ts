/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const permissions = z
  .object({
    can_control_playback: z.boolean(),
    can_advance_turn: z.boolean(),
    can_start_game: z.boolean(),
    can_start_turn: z.boolean(),
    can_restart_game: z.boolean(),
    can_see_assumptions: z.boolean(),
    can_make_assumptions: z.boolean(),
  })
  .strict()
  .describe(
    "Caller-specific permissions computed by `Songy.Authorization.permissions/2`",
  );
