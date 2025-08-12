import type { Track } from './track';
import type { Snippet } from 'svelte';
import type { DndEvent, TransformDraggedElementFunction } from 'svelte-dnd-action';

/**
 * Timeline item wrapper for drag and drop functionality.
 * 
 * Wraps any data type with required id property for dndzone.
 */
export interface TimelineItem<T = any> {
  /** Unique identifier required by dndzone */
  id: string | number;
  
  /** The actual data payload */
  track: T;
  
  /** Optional properties for UI state */
  current?: boolean;
  revealed?: boolean;
}

/**
 * Timeline-specific item for track data
 */
export type TrackTimelineItem = TimelineItem<Track>;

/**
 * Props for Timeline component with only needed dndzone options
 */
export interface TimelineProps<T = any> {
  /** Array of timeline items */
  items: TimelineItem<T>[];
  
  /** Animation duration for flip animations */
  flipDurationMs?: number;
  
  /** Custom consider handler */
  onConsider?: (event: CustomEvent<DndEvent<TimelineItem<T>>>) => void;
  
  /** Custom finalize handler */
  onFinalize?: (event: CustomEvent<DndEvent<TimelineItem<T>>>) => void;
  
  /** DndZone type identifier */
  type?: string;
  
  /** Disable dragging */
  dragDisabled?: boolean;
  
  /** Disable morphing while dragging */
  morphDisabled?: boolean;
  
  /** Disable dropping from other zones */
  dropFromOthersDisabled?: boolean;
  
  /** Zone tab index */
  zoneTabIndex?: number;
  
  /** Zone item tab index */
  zoneItemTabIndex?: number;
  
  /** Drop target styling */
  dropTargetStyle?: Record<string, any>;
  
  /** Drop target CSS classes */
  dropTargetClasses?: string[];
  
  /** Transform dragged element function */
  transformDraggedElement?: (element: HTMLElement, data: TimelineItem<T>, index: number) => void;
  
  /** Disable auto ARIA */
  autoAriaDisabled?: boolean;
  
  /** Centre dragged element on cursor */
  centreDraggedOnCursor?: boolean;
  
  /** Disable drop animation */
  dropAnimationDisabled?: boolean;
  
  /** Snippet for rendering children */
  children?: Snippet<[TimelineItem<T>]>;
}
