import type { Permissions } from "~contracts";

export const basePermissions = {
  can_control_playback: false,
  can_advance_turn: false,
  can_start_game: false,
  can_start_turn: false,
  can_restart_game: false,
  can_see_assumptions: false,
  can_make_assumptions: false,
} satisfies Permissions;

export const ownerPermissions: Permissions = {
  ...basePermissions,
  can_start_game: true,
} satisfies Permissions;
