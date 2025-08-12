<script lang="ts">
  import { setContext } from "svelte";
  import { getChannelContext } from "~shared/context/channel";
  import type { User } from "~shared/types/user";
  import type { ScopeContext } from "~shared/context/scope";
  import type { Snippet } from "svelte";

  let { children }: { children: Snippet } = $props();

  const { channel } = $derived.by(getChannelContext);

  let context: ScopeContext = $state({ user: null });

  $effect(() => {
    if (!channel) return;

    channel
      .push("get_current_user", {})
      .receive("ok", (response: User) => {
        context.user = response;
      })
      .receive("error", (error: any) => {
        console.error("Failed to get user:", error);
      });
  });

  setContext<ScopeContext>("scope", context);
</script>

{@render children?.()}
