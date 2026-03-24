<script lang="ts">
  import type { Snippet } from "svelte";
  import { setScopeContext, type ScopeContext } from "~components/scope.svelte";
  import type { User } from "~contracts";

  interface Props {
    children?: Snippet;
    user: User | null;
  }

  let { children, user }: Props = $props();

  const context: ScopeContext = {
    get user() {
      return user;
    },
  };

  setScopeContext(context);
</script>

{@render children?.()}
