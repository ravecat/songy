<script lang="ts">
  import type { Snippet } from "svelte";
  import MediaProvider from "~components/media_provider.svelte";

  interface Props {
    children?: Snippet;
    provider?: string;
  }

  let { children, provider = "itunes" }: Props = $props();
</script>

<MediaProvider {provider}>
  {@render children?.()}
</MediaProvider>
