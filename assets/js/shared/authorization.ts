import type { Game } from '~shared/types/game';
import type { User } from '~shared/types/user';
import { GAME_STATUS } from '~shared/types/game';
import { TURN_PHASE } from '~shared/types/turn';

/**
 * Role represents the user's role in the game.
 * Roles are computed dynamically based on game state.
 */
export type Role = 'owner' | 'player' | 'challenger' | 'guest';

/**
 * Permission context represents the current state/phase plus user stance.
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
  /** The user's roles in this game */
  roles: Role[];
  /** The current game context */
  context: PermissionContext;
  /** Whether this user is the active player */
  isActivePlayer: boolean;
  /** Whether this user is the game owner */
  isOwner: boolean;
}

type PermissionFlags = Pick<
  GamePermissions,
  | 'canControlPlayback'
  | 'canAdvanceTurn'
  | 'canStartGame'
  | 'canAdvanceFromWaiting'
  | 'showPlayAgain'
>;

const DEFAULT_PERMISSION_FLAGS: PermissionFlags = {
  canControlPlayback: false,
  canAdvanceTurn: false,
  canStartGame: false,
  canAdvanceFromWaiting: false,
  showPlayAgain: false,
};

const PERMISSIONS_BY_CONTEXT: Record<PermissionContext, PermissionFlags> = {
  lobby_owner: { ...DEFAULT_PERMISSION_FLAGS, canStartGame: true },
  lobby_participant: DEFAULT_PERMISSION_FLAGS,
  turn_waiting_active: { ...DEFAULT_PERMISSION_FLAGS, canAdvanceFromWaiting: true },
  turn_waiting_idle: DEFAULT_PERMISSION_FLAGS,
  turn_ready_active: {
    ...DEFAULT_PERMISSION_FLAGS,
    canControlPlayback: true,
    canAdvanceTurn: true,
  },
  turn_ready_owner: { ...DEFAULT_PERMISSION_FLAGS, canControlPlayback: true },
  turn_ready_spectator: DEFAULT_PERMISSION_FLAGS,
  turn_challenging_active: {
    ...DEFAULT_PERMISSION_FLAGS,
    canControlPlayback: true,
    canAdvanceTurn: true,
  },
  turn_challenging_owner: { ...DEFAULT_PERMISSION_FLAGS, canControlPlayback: true },
  turn_challenging_spectator: DEFAULT_PERMISSION_FLAGS,
  turn_results_active: { ...DEFAULT_PERMISSION_FLAGS, canAdvanceTurn: true },
  turn_results_owner: DEFAULT_PERMISSION_FLAGS,
  turn_results_spectator: DEFAULT_PERMISSION_FLAGS,
  game_finished: { ...DEFAULT_PERMISSION_FLAGS, showPlayAgain: true },
};

/**
 * Initializes the authorization system.
 * In the browser, we use hardcoded permissions that are synced with the backend policy rules.
 * The backend enforces permissions via Casbin on the server side.
 */
export function initCasbin(): void {
  // Frontend uses hardcoded permissions that match the backend Casbin policy rules
  // Backend enforces permissions via Casbin.EnforcerServer.allow?/2
  // This approach avoids Buffer/Node.js API issues in the browser
}

/**
 * Computes the user's roles based on game state and user info.
 * Roles are computed dynamically based on user's relationship to the game.
 *
 * This logic MUST match the backend compute_roles function in Songy.Authorization
 * to ensure consistent permission checks across frontend and backend.
 *
 * @returns Array of roles the user has in this game
 */
function computeRoles(game: Game | null, user: User | null): Role[] {
  if (!game || !user) return [];

  const isOwner = game.owner_id === user.uuid;
  const activePlayerId = game.queue[game.cursor];
  const isActive = activePlayerId === user.uuid;

  // Finished game - everyone is a guest
  if (game.status === GAME_STATUS.FINISHED) {
    return ['guest'];
  }

  const roles: Role[] = [];

  // Add roles in priority order
  if (isOwner) roles.push('owner');
  if (isActive) roles.push('player');

  // Challenger only in in_progress, not owner, not active
  if (game.status === GAME_STATUS.IN_PROGRESS && !isActive && !isOwner) {
    roles.push('challenger');
  }

  return roles;
}

/**
 * Computes the current permission context based on game status and user stance.
 *
 * @returns The current permission context
 */
function computePermissionContext(
  game: Game | null,
  user: User | null,
  isOwner: boolean,
  isActivePlayer: boolean
): PermissionContext {
  if (!game || !user) return 'lobby_participant';

  switch (game.status) {
    case GAME_STATUS.WAITING:
      return isOwner ? 'lobby_owner' : 'lobby_participant';
    case GAME_STATUS.IN_PROGRESS:
      switch (game.turn?.phase) {
        case TURN_PHASE.WAITING:
          return isActivePlayer ? 'turn_waiting_active' : 'turn_waiting_idle';
        case TURN_PHASE.READY:
          if (isActivePlayer) return 'turn_ready_active';
          if (isOwner) return 'turn_ready_owner';
          return 'turn_ready_spectator';
        case TURN_PHASE.CHALLENGING:
          if (isActivePlayer) return 'turn_challenging_active';
          if (isOwner) return 'turn_challenging_owner';
          return 'turn_challenging_spectator';
        case TURN_PHASE.RESULTS:
          if (isActivePlayer) return 'turn_results_active';
          if (isOwner) return 'turn_results_owner';
          return 'turn_results_spectator';
        default:
          return 'lobby_participant';
      }
    case GAME_STATUS.FINISHED:
      return 'game_finished';
    default:
      return 'lobby_participant';
  }
}

/**
 * Main permission computation function.
 * Pure function: takes game state and user info, returns permissions.
 *
 * NOTE: This function is synchronous for use in reactive Svelte stores.
 * Permissions are computed based on hardcoded rules that match the backend Casbin policy.
 * The backend enforces these permissions on the server side via Casbin.
 *
 * @param game - Current game state from server, or null if not loaded
 * @param currentUser - Current authenticated user, or null if not loaded
 * @returns Computed permissions object with all allowed actions and metadata
 */
export function computeGamePermissions(
  game: Game | null,
  currentUser: User | null
): GamePermissions {
  const roles = computeRoles(game, currentUser);

  const isOwner = game?.owner_id === currentUser?.uuid && game != null && currentUser != null;
  const activePlayerId = game?.queue[game?.cursor ?? 0];
  const isActivePlayer =
    activePlayerId === currentUser?.uuid && activePlayerId != null && currentUser != null;
  const context = computePermissionContext(game, currentUser, isOwner, isActivePlayer);
  const permissions = PERMISSIONS_BY_CONTEXT[context] ?? DEFAULT_PERMISSION_FLAGS;

  return {
    ...permissions,
    roles,
    context,
    isActivePlayer,
    isOwner,
  };
}
