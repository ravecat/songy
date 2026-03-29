<script lang="ts">
  import type { SharedPageProps } from "@inertiajs/core";
  import type { Snippet } from "svelte";
  import DefaultMediaProvider from "~components/default_media_provider.svelte";
  import Spotify from "~components/spotify.svelte";

  type Provider = NonNullable<SharedPageProps["scope"]["provider"]>;

  interface Props {
    provider?: Provider;
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
