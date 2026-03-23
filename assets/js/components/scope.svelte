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
  import { getGameContext } from "~components/game_provider.svelte";
  import Equalizer from "~components/equalizer.svelte";
  import type { Snippet } from "svelte";

  let { children }: { children: Snippet } = $props();

  const { channel } = $derived.by(getGameContext);

  let context = $state<ScopeContext>({ user: null });

  $effect(() => {
    channel
      .push("get_current_user", {})
      .receive("ok", (response) => {
        context.user = response;
      });
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
