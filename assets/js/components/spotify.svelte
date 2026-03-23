<script lang="ts">
  import type { Snippet } from "svelte";
  import { getGameContext } from "~components/game_provider.svelte";
  import {
    useSpotifyPlayer,
    SPOTIFY_EVENT,
  } from "~/shared/hooks/spotify.svelte";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();

  const { channel } = $derived.by(getGameContext);

  useSpotifyPlayer({
    name: "Songy room",
    getOAuthToken: (cb) => {
      channel
        .push("get_provider", {})
        .receive("ok", ({ token }) => {
          cb(token);
        });
    },
    on: {
      [SPOTIFY_EVENT.READY]: ({ device_id }: { device_id: string }) => {
        channel.push("update_provider", { device_id });
      },
    },
  });
</script>

{@render children?.()}
