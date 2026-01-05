import { MemoryAdapter, Model, newEnforcer } from 'casbin-core';
import casbinModel from '~priv/authorization/model.conf?raw';
import casbinPolicy from '~priv/authorization/policies.csv?raw';
import type { Game } from '~shared/types/game';
import type { User } from '~shared/types/user';
import { GAME_STATUS } from '~shared/types/game';
import { TURN_PHASE } from '~shared/types/turn';

/**
 * Role represents the user's subject in the authorization model.
 * The subject resolution mirrors Songy.Authorization.subject/2.
 */
type Role = 'owner' | 'player' | 'challenger';

/**
 * Actions defined in priv/authorization/policies.csv.
 */
type Action =
  | 'start_game'
  | 'start_playback'
  | 'pause_playback'
  | 'next_phase'
  | 'make_assumption'
  | 'reorder_timeline'
  | 'spectate';

/**
 * Computed permissions for a user in a specific game context.
 * These permissions determine what actions the UI should allow.
 */
interface Permissions {
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

// Casbin enforcer initialized once from raw model and policy files (no role lookups in matcher).
const enforcer = await (async () => {
  const m = new Model(casbinModel);
  const adapter = new MemoryAdapter(casbinPolicy);
  return newEnforcer(m, adapter);
})();

function resolveSubject(game: Game | null, user: User | null): Role | null {
  if (!game || !user) return null;

  if (game.owner_id === user.uuid) return 'owner';

  const activePlayerId = game.queue[game.cursor];
  if (activePlayerId === user.uuid) return 'player';

  return 'challenger';
}

function resolveState(game: Game | null): string {
  return game?.status ?? 'nil';
}

function resolvePhase(game: Game | null): string {
  return game?.turn?.phase ?? 'nil';
}

/**
 * Checks if a user can perform an action using authorization policies.
 * Mirrors Songy.Authorization.can?/3.
 */
function can(
  game: Game | null,
  user: User | null,
  action: Action
): boolean {
  const subject = resolveSubject(game, user);

  if (!subject) return false;

  const state = resolveState(game);
  const phase = resolvePhase(game);

  return enforcer.enforceSync(subject, state, phase, action);
}

/**
 * Main permission computation function.
 * Pure function: takes game state and user info, returns permissions.
 */
export function computePermissions(
  game: Game | null,
  currentUser: User | null
): Permissions {
  const canStartGame = can(game, currentUser, 'start_game');
  const canStartPlayback = can(game, currentUser, 'start_playback');
  const canPausePlayback = can(game, currentUser, 'pause_playback');
  const canControlPlayback = canStartPlayback || canPausePlayback;
  const canNextPhase = can(game, currentUser, 'next_phase');

  const isInProgress = game?.status === GAME_STATUS.IN_PROGRESS;
  const isWaitingPhase = isInProgress && game?.turn?.phase === TURN_PHASE.WAITING;

  const canAdvanceFromWaiting = canNextPhase && isWaitingPhase;
  const canAdvanceTurn = canNextPhase && isInProgress && !isWaitingPhase;
  const canRestartGame = Boolean(game && currentUser && game.status === GAME_STATUS.FINISHED);

  return {
    canControlPlayback,
    canAdvanceTurn,
    canStartGame,
    canAdvanceFromWaiting,
    canRestartGame,
  };
}
