/**
 * User permissions for allowed actions in a game context.
 * These flags are computed on the server and sent via the "permissions" channel event.
 */
export interface Permissions {
  /** Whether user can control Spotify playback (play/pause) */
  can_control_playback: boolean;

  /** Whether user can advance to next turn/phase */
  can_advance_turn: boolean;

  /** Whether user can start the game (owner in lobby) */
  can_start_game: boolean;

  /** Whether user can advance from waiting phase */
  can_ready: boolean;

  /** Whether to show the play again button */
  can_restart_game: boolean;
}
