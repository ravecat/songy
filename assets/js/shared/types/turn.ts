import type { Track } from './track';

/**
 * Turn phases and turn state management.
 */

/**
 * Possible phases during a game turn
 */
export enum TURN_PHASE {
  WAITING = 'waiting',
  READY = 'ready',
  CHALLENGING = 'challenging',
  RESULTS = 'results'
}

/**
 * Represents an active turn in the music guessing game.
 *
 * Contains turn-specific state: current phase, timeline snapshot
 * for challenging, and player assumptions.
 *
 * Note: queue, cursor, and track are stored in Game, not Turn!
 */
export interface Turn {
  /** Current phase of the turn */
  phase: TURN_PHASE;

  /** Timeline snapshot for challenging phase */
  timeline?: Track[];

  /** Player position assumptions: array of {position, user_id} objects */
  assumptions?: Array<{position: number; user_id: string}>;

  /** Winner of the round (set in results phase) */
  winner_id?: string;
}
