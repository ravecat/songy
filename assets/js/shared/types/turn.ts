import type { Track } from './track';

/**
 * Turn phases and turn state management.
 */

/**
 * Possible phases during a game turn
 */
export enum TURN_PHASE {
  WAITING = 'turn_waiting',
  READY = 'turn_ready',
  STEADY = 'turn_steady',
  CHALLENGING = 'turn_challenging',
  RESULTS = 'turn_results'
}

/**
 * Represents an active turn in the music guessing game.
 * 
 * Contains information about current player, challengers,
 * active track, and turn phase.
 */
export interface Turn {
  /** Queue of player UUIDs */
  queue: string[];

  /** Index of current active player in queue */
  cursor: number;

  /** List of challenger UUIDs */
  challengers: string[];

  /** Currently playing track */
  track?: Track;

  /** Current phase of the turn */
  phase: TURN_PHASE;
}
