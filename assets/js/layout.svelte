<script lang="ts">
  import type { Snippet } from "svelte";
  import MediaProvider from "~components/media_provider.svelte";
  import { provider } from "~/stores/scope";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();
</script>

<MediaProvider provider={$provider}>
  {@render children?.()}
</MediaProvider>
