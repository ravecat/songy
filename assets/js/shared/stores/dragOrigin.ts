import { writable } from 'svelte/store';

/**
 * Simple store to track drag origin zone identifier
 */
export const dragOriginZone = writable<string | null>(null);
