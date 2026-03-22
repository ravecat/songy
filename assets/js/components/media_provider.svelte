<script lang="ts">
  import type { Snippet } from "svelte";
  import DefaultMediaProvider from "~components/default_media_provider.svelte";
  import Spotify from "~components/spotify.svelte";

  interface Props {
    provider?: string;
    children?: Snippet;
  }

  let { provider = "itunes", children }: Props = $props();
</script>

{#if provider === "spotify"}
  <Spotify>
    {@render children?.()}
  </Spotify>
{:else}
  <DefaultMediaProvider>
    {@render children?.()}
  </DefaultMediaProvider>
{/if}
