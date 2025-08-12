import { getContext } from "svelte";
import type { User } from "~shared/types/user";

/**
 * Scope context interface providing user information
 */
export interface ScopeContext {
  /** Current authenticated user */
  user: User;
}

/**
 * Get the scope context from Svelte's context system
 * 
 * Must be called within a component that has a Scope parent component.
 * Provides access to the current user information.
 * 
 * @returns Scope context containing user data
 * @throws Error if called outside of a Scope component
 */
export function getScopeContext(): ScopeContext {
  const context = getContext<ScopeContext>("scope");

  if (!context) {
    throw new Error(
      "getScopeContext() must be called within a Scope component"
    );
  }

  return context;
}
