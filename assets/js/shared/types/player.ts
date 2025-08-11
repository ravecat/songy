/**
 * Player state for game session playback control.
 * 
 * Manages internal playback state controlled by game logic.
 */
export interface Player {
  /** Whether music is currently playing */
  is_playback: boolean;
}
