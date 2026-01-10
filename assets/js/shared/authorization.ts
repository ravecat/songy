/**
 * @deprecated This module is deprecated. Permissions are now computed on the server
 * and sent via the "permissions" channel event. This file is kept for reference only.
 * Use the permissions received from the GameContext instead.
 */

import type { Game } from '~shared/types/game';
import type { User } from '~shared/types/user';
import { GAME_STATUS } from '~shared/types/game';
import { TURN_PHASE } from '~shared/types/turn';

/**
 * Role represents the user's subject in the authorization model.
 */
export type Role = 'owner' | 'player' | 'challenger';

/**
 * Computed permissions for a user in a specific game context.
 * These permissions determine what actions the UI should allow.
 */
export interface Permissions {
  /** Whether user can control Spotify playback */
  canControlPlayback: boolean;
  /** Whether user can advance to next turn/phase */
  canAdvanceTurn: boolean;
  /** Whether user can start the game (owner in lobby) */
  canStartGame: boolean;
  /** Whether user can advance from waiting phase */
  canAdvanceFromWaiting: boolean;
  /** Whether to show the play again button */
  canRestartGame: boolean;
}

/**
 * Default empty permissions (no access)
 */
export const defaultPermissions: Permissions = {
  canControlPlayback: false,
  canAdvanceTurn: false,
  canStartGame: false,
  canAdvanceFromWaiting: false,
  canRestartGame: false,
};

/**
 * Determines if the user is the game owner
 */
function isOwner(game: Game | null, user: User | null): boolean {
  return !!(game && user && game.owner_id === user.uuid);
}

/**
 * Determines if the user is the active player
 */
function isPlayer(game: Game | null, user: User | null): boolean {
  return !!(
    game &&
    user &&
    game.queue[game.cursor] === user.uuid &&
    !isOwner(game, user)
  );
}

/**
 * Determines if the user is a challenger (not owner, not active player)
 */
function isChallenger(game: Game | null, user: User | null): boolean {
  if (!game || !user) {
    return false;
  }

  return !isOwner(game, user) && !isPlayer(game, user);
}

/**
 * Computes permissions based on user role and game state
 */
function computePermissions(
  game: Game | null,
  user: User | null
): Permissions {
  if (!game || !user) {
    return defaultPermissions;
  }

  const status = game.status;
  const phase = game.turn?.phase ?? TURN_PHASE.WAITING;
  const isInProgress = status === GAME_STATUS.IN_PROGRESS;
  const isFinished = status === GAME_STATUS.FINISHED;
  const isWaitingPhase = phase === TURN_PHASE.WAITING;
  const isReadyPhase = phase === TURN_PHASE.READY;
  const isChallengingPhase = phase === TURN_PHASE.CHALLENGING;
  const isResultsPhase = phase === TURN_PHASE.RESULTS;

  // Default permissions for all roles
  let canControlPlayback = false;
  let canAdvanceTurn = false;
  let canStartGame = false;
  let canAdvanceFromWaiting = false;
  let canRestartGame = false;

  // Owner permissions
  if (isOwner(game, user)) {
    if (status === GAME_STATUS.WAITING) {
      canStartGame = true;
    }

    if (isInProgress) {
      if (isWaitingPhase) {
        canControlPlayback = true;
        canAdvanceFromWaiting = true;
      } else if (isReadyPhase) {
        canControlPlayback = true;
      } else if (isChallengingPhase) {
        canControlPlayback = true;
      } else if (isResultsPhase) {
        canAdvanceTurn = true;
      }
    }

    if (isFinished) {
      canRestartGame = true;
    }
  }

  // Player (active player) permissions
  if (isPlayer(game, user)) {
    if (isInProgress) {
      if (isWaitingPhase) {
        canControlPlayback = true;
        canAdvanceFromWaiting = true;
      } else if (isReadyPhase) {
        canControlPlayback = true;
        canAdvanceTurn = true;
      } else if (isResultsPhase) {
        canAdvanceTurn = true;
      }
    }

    if (isFinished) {
      canRestartGame = true;
    }
  }

  // Challenger permissions
  if (isChallenger(game, user)) {
    // Can only control playback during challenging phase
    if (isInProgress && isChallengingPhase) {
      canControlPlayback = true;
    }

    // Can always restart finished game
    if (isFinished) {
      canRestartGame = true;
    }
  }

  return {
    canControlPlayback,
    canAdvanceTurn,
    canStartGame,
    canAdvanceFromWaiting,
    canRestartGame,
  };
}

/**
 * Computes permissions for a user in a game context
 * Use with $derived in Svelte components for reactivity
 *
 * Example:
 * const permissions = $derived(getPermissions(game, user));
 */
export function getPermissions(
  game: Game | null,
  user: User | null
): Permissions {
  return computePermissions(game, user);
}
