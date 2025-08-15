<script lang="ts" module>
  import { getContext, setContext } from "svelte";
  import type { User } from "~shared/types/user";

  /**
   * Scope context interface providing user information
   */
  export interface ScopeContext {
    /** Current authenticated user */
    user: User;
  }

  // Context key for scope context - using object literal for better testability
  const SCOPE_CONTEXT_KEY = {};

  export { SCOPE_CONTEXT_KEY };

  /**
   * Set the scope context in Svelte's context system
   *
   * Must be called during component initialization to establish scope context
   * for child components. This function is part of the public API.
   *
   * @param context Scope context containing user information
   */
  export function setScopeContext(context: ScopeContext): void {
    setContext(SCOPE_CONTEXT_KEY, context);
  }

  /**
   * Get the scope context from Svelte's context system
   *
   * Must be called within a component that has a Scope parent component.
   * Provides access to the current user information.
   *
   * @returns Scope context containing user data
   * @throws Error if called outside of a scope context
   */
  export function getScopeContext(): ScopeContext {
    const context = getContext<ScopeContext>(SCOPE_CONTEXT_KEY);

    if (!context) {
      throw new Error(
        `${getScopeContext.name}() must be called within a scope context`
      );
    }

    return context;
  }
</script>

<script lang="ts">
  import { getGameContext } from "~components/GameContext.svelte";
  import type { Snippet } from "svelte";

  let { children }: { children: Snippet } = $props();

  const { channel } = $derived.by(getGameContext);

  let context = $state<ScopeContext>({ user: null! });

  $effect(() => {
    channel.push("get_current_user", {}).receive("ok", (response: User) => {
      context.user = response;
    });
  });

  setScopeContext(context);
</script>

{@render children?.()}
