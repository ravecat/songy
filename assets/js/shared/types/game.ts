import type { User } from './user';
import type { Track } from './track';
import type { Player } from './player';
import type { Turn } from './turn';

/**
 * Game state and related types.
 */

/**
 * Game status indicating current state
 */
export enum GAME_STATUS {
  WAITING = 'waiting',       // Waiting for players to join
  IN_PROGRESS = 'in_progress', // Game is actively being played
  FINISHED = 'finished'      // Game has ended
}

/**
 * Represents a multiplayer game room for the music quiz.
 *
 * Contains all game state including participants, settings,
 * current turn information, and player timelines.
 */
export interface Game {
  /** Unique game room identifier */
  id: string;

  /** List of participants in the game */
  participants: User[];

  /** Maximum number of allowed participants */
  max_participants: number;

  /** Maximum score needed to win the game */
  max_score: number;

  /** Game creation timestamp */
  created_at: string;

  /** Current game status */
  status: GAME_STATUS;

  /** UUID of the game owner/creator */
  owner_id: string;

  /** Player state for playback control, null in waiting phase */
  player: Player | null;

  /** Current turn information, null in waiting/finished phases */
  turn: Turn | null;

  /** Player timelines mapping UUID to track arrays */
  timelines: Record<string, Track[]>;

  /** Player scores mapping UUID to scores */
  scores: Record<string, number>;

  /** Players queue containing UUIDs in turn order */
  queue: string[];

  /** Index of current active player in queue */
  cursor: number;

  /** Currently playing track, null when no track active */
  track: Track | null;
}
