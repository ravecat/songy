<script lang="ts">
  import type { Snippet } from "svelte";
  import DefaultMediaProvider from "~components/default_media_provider.svelte";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();
</script>

<DefaultMediaProvider>
  {@render children?.()}
</DefaultMediaProvider>
