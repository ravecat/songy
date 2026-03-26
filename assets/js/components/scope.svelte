<script lang="ts" module>
  import { createContext } from "svelte";
  import type { User } from "~contracts";

  /**
   * Scope context interface providing user information
   */
  export interface ScopeContext {
    /** Current authenticated user */
    user: User | null;
  }

  export const [getScopeContext, setScopeContext] =
    createContext<ScopeContext>();
</script>

<script lang="ts">
  import type { Snippet } from "svelte";

  let { children, currentUser }: { children: Snippet; currentUser: User } =
    $props();

  let context = $state<ScopeContext>({ user: null });

  $effect(() => {
    context.user = currentUser;
  });

  setScopeContext(context);
</script>

{@render children?.()}
