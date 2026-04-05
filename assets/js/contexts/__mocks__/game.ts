import { writable } from "svelte/store";
import { vi } from "vitest";

const session = writable({
  snapshot: null,
  status: "loading",
  error: null,
});

export const getGameContext = vi.fn(() => session);
export const setGameContext = vi.fn();
