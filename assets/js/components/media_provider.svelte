<script lang="ts">
  import type { Snippet } from "svelte";
  import { getGameContext } from "~components/game_channel.svelte";
  import DefaultMediaProvider from "~components/default_media_provider.svelte";
  import Spotify from "~components/spotify.svelte";
  import { Provider } from "~shared/types/provider";

  interface Props {
    provider?: Provider;
    children?: Snippet;
  }

  let { provider, children }: Props = $props();

  const { game } = $derived.by(getGameContext);

  const resolvedProvider = $derived.by(() => {
    return provider ?? game?.provider ?? Provider.ITUNES;
  });
</script>

{#if resolvedProvider === Provider.SPOTIFY}
  <Spotify>
    {@render children?.()}
  </Spotify>
{:else}
  <DefaultMediaProvider>
    {@render children?.()}
  </DefaultMediaProvider>
{/if}
