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
  import { getGameContext } from "~/contexts/game";
  import Equalizer from "~components/equalizer.svelte";
  import type { Snippet } from "svelte";

  let { children }: { children: Snippet } = $props();

  const session = $derived.by(getGameContext);

  let context = $state<ScopeContext>({ user: null });

  $effect(() => {
    let active = true;

    void session
      .getCurrentUser()
      .then((response) => {
        if (active) {
          context.user = response;
        }
      })
      .catch(() => {});

    return () => {
      active = false;
    };
  });

  setScopeContext(context);
</script>

{#if !context.user}
  <div class="scope-loader" role="status" aria-label="Loading">
    <Equalizer />
  </div>
{:else}
  {@render children?.()}
{/if}

<style>
  .scope-loader {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100%;
  }
</style>
