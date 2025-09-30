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
  uuid: string;

  /** List of participants in the game */
  participants: User[];

  /** Maximum number of allowed participants */
  max_participants: number;

  /** Game creation timestamp */
  created_at: string;

  /** Current game status */
  status: GAME_STATUS;

  /** UUID of the game owner/creator */
  owner_uuid: string;

  /** Player state for playback control */
  player: Player;

  /** Current turn information */
  turn: Turn;

  /** Player timelines mapping UUID to track arrays */
  timelines: Record<string, Track[]>;

  /** Player scores mapping UUID to scores */
  scores: Record<string, number>;
}
