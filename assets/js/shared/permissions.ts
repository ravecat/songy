import type { Game } from '~shared/types/game';
import type { User } from '~shared/types/user';
import { GAME_STATUS } from '~shared/types/game';
import { TURN_PHASE } from '~shared/types/turn';

/**
 * Permission context represents a unique combination of game state
 * that determines what actions are allowed for the current user.
 */
export type PermissionContext =
  | 'lobby_owner'
  | 'lobby_participant'
  | 'turn_waiting_active'
  | 'turn_waiting_idle'
  | 'turn_ready_active'
  | 'turn_ready_owner'
  | 'turn_ready_spectator'
  | 'turn_challenging_active'
  | 'turn_challenging_owner'
  | 'turn_challenging_spectator'
  | 'turn_results_active'
  | 'turn_results_owner'
  | 'turn_results_spectator'
  | 'game_finished';

/**
 * Computed permissions for a user in a specific game context.
 * These permissions determine what actions the UI should allow.
 */
export interface GamePermissions {
  /** Whether user can control Spotify playback */
  canControlPlayback: boolean;
  /** Whether user can advance to next turn/phase */
  canAdvanceTurn: boolean;
  /** Whether user can start the game (owner in lobby) */
  canStartGame: boolean;
  /** Whether user can advance from waiting phase */
  canAdvanceFromWaiting: boolean;
  /** Whether to show the play again button */
  showPlayAgain: boolean;

  // Metadata for debugging and UI hints
  /** The computed permission context */
  context: PermissionContext;
  /** Whether this user is the active player */
  isActivePlayer: boolean;
  /** Whether this user is the game owner */
  isOwner: boolean;
}

/**
 * Determines the permission context based on game state and user info.
 * A context is a unique combination of game state that has consistent permissions.
 *
 * @returns One of 14 predefined permission contexts
 */
function computeContext(
  game: Game | null,
  currentUser: User | null
): PermissionContext {
  if (!game || !currentUser) {
    return 'lobby_participant';
  }

  const isOwner = game.owner_id === currentUser.uuid;
  const activePlayerId = game.queue[game.cursor];
  const isActivePlayer = activePlayerId === currentUser.uuid;
  const gameStatus = game.status;
  const turnPhase = game.turn?.phase;

  // Game finished
  if (gameStatus === GAME_STATUS.FINISHED) {
    return 'game_finished';
  }

  // Waiting for players (lobby)
  if (gameStatus === GAME_STATUS.WAITING) {
    return isActivePlayer && isOwner ? 'lobby_owner' : 'lobby_participant';
  }

  // In-progress game - by turn phase
  if (gameStatus === GAME_STATUS.IN_PROGRESS) {
    if (turnPhase === TURN_PHASE.WAITING) {
      return isActivePlayer ? 'turn_waiting_active' : 'turn_waiting_idle';
    }

    if (turnPhase === TURN_PHASE.READY) {
      if (isActivePlayer) return 'turn_ready_active';
      if (isOwner) return 'turn_ready_owner';
      return 'turn_ready_spectator';
    }

    if (turnPhase === TURN_PHASE.CHALLENGING) {
      if (isActivePlayer) return 'turn_challenging_active';
      if (isOwner) return 'turn_challenging_owner';
      return 'turn_challenging_spectator';
    }

    if (turnPhase === TURN_PHASE.RESULTS) {
      if (isActivePlayer) return 'turn_results_active';
      if (isOwner) return 'turn_results_owner';
      return 'turn_results_spectator';
    }
  }

  return 'lobby_participant';
}

/**
 * Permission matrix: maps each context to allowed actions.
 * This is the single source of truth for what users can do.
 */
const PERMISSION_RULES: Record<
  PermissionContext,
  Omit<GamePermissions, 'context' | 'isActivePlayer' | 'isOwner'>
> = {
  // Lobby - waiting for players to join
  lobby_owner: {
    canControlPlayback: false,
    canAdvanceTurn: false,
    canStartGame: true,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },
  lobby_participant: {
    canControlPlayback: false,
    canAdvanceTurn: false,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },

  // Turn waiting phase - waiting for active player to confirm
  turn_waiting_active: {
    canControlPlayback: false,
    canAdvanceTurn: false,
    canStartGame: false,
    canAdvanceFromWaiting: true,
    showPlayAgain: false,
  },
  turn_waiting_idle: {
    canControlPlayback: false,
    canAdvanceTurn: false,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },

  // Turn ready phase - track is playing, active player is guessing
  turn_ready_active: {
    canControlPlayback: true,
    canAdvanceTurn: true,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },
  turn_ready_owner: {
    canControlPlayback: true,
    canAdvanceTurn: false,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },
  turn_ready_spectator: {
    canControlPlayback: false,
    canAdvanceTurn: false,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },

  // Turn challenging phase - challenging assumptions
  turn_challenging_active: {
    canControlPlayback: true,
    canAdvanceTurn: true,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },
  turn_challenging_owner: {
    canControlPlayback: true,
    canAdvanceTurn: false,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },
  turn_challenging_spectator: {
    canControlPlayback: false,
    canAdvanceTurn: false,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },

  // Turn results phase - showing results
  turn_results_active: {
    canControlPlayback: false,
    canAdvanceTurn: true,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },
  turn_results_owner: {
    canControlPlayback: false,
    canAdvanceTurn: false,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },
  turn_results_spectator: {
    canControlPlayback: false,
    canAdvanceTurn: false,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: false,
  },

  // Game finished
  game_finished: {
    canControlPlayback: false,
    canAdvanceTurn: false,
    canStartGame: false,
    canAdvanceFromWaiting: false,
    showPlayAgain: true,
  },
};

/**
 * Main permission computation function.
 * Pure function: takes game state and user info, returns permissions.
 *
 * @param game - Current game state from server, or null if not loaded
 * @param currentUser - Current authenticated user, or null if not loaded
 * @returns Computed permissions object with all allowed actions and metadata
 */
export function computeGamePermissions(
  game: Game | null,
  currentUser: User | null
): GamePermissions {
  const context = computeContext(game, currentUser);
  const permissions = PERMISSION_RULES[context];

  const isOwner = (game?.owner_id ?? null) === (currentUser?.uuid ?? null) && game != null && currentUser != null;
  const activePlayerId = game?.queue[game?.cursor ?? 0];
  const isActivePlayer = (activePlayerId ?? null) === (currentUser?.uuid ?? null) && activePlayerId != null && currentUser != null;

  return {
    ...permissions,
    context,
    isActivePlayer,
    isOwner,
  };
}
