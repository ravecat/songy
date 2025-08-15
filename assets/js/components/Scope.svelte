<script lang="ts">
  import { setContext } from "svelte";
  import { getGameContext } from "~components/GameContext.svelte";
  import type { User } from "~shared/types/user";
  import type { ScopeContext } from "~shared/context/scope";
  import type { Snippet } from "svelte";

  let { children }: { children: Snippet } = $props();

  const { channel } = $derived.by(getGameContext);

  let context: ScopeContext = $state({ user: null! });

  $effect(() => {
    channel.push("get_current_user", {}).receive("ok", (response: User) => {
      context.user = response;
    });
  });

  setContext<ScopeContext>("scope", context);
</script>

{@render children?.()}
