import type { Track } from './track';

/**
 * Turn phases and turn state management.
 */

/**
 * Possible phases during a game turn
 */
export type TurnPhase = 
  | 'turn_waiting'      // Waiting for player readiness
  | 'turn_playing'      // Playing track and placing on timeline  
  | 'turn_challenging'  // Challenge phase from other players
  | 'turn_results';     // Results and scoring phase

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
  current_player_index: number;
  
  /** List of challenger UUIDs */
  challengers: string[];
  
  /** Currently playing track */
  track?: Track;
  
  /** Current phase of the turn */
  phase: TurnPhase;
}
