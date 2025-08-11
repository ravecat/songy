/**
 * User entity representing a game participant.
 * 
 * Users are temporary entities stored in memory during game sessions.
 * Each user has a unique UUID, display name, and avatar URL.
 */
export interface User {
  /** Unique identifier for the user */
  uuid: string;
  
  /** Display name (generated based on UUID) */
  name: string;
  
  /** Avatar image URL (generated based on UUID) */
  avatar_url: string;
}
