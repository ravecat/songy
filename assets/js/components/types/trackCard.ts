import type { Track } from '~shared/types/track';

/**
 * Props interface for TrackCard component.
 * 
 * Defines the expected properties for the TrackCard Svelte component
 * including track data, visual state, and interaction state.
 */
export interface TrackCardProps {
  /** Track data to display */
  track: Track;
  
  /** Whether the track card is revealed (shows content) */
  revealed?: boolean;
  
  /** Whether the track is in ready state */
  ready?: boolean;
}
