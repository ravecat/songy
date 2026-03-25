<script lang="ts">
  import type { Snippet } from "svelte";
  import { getGameContext } from "~/contexts/game";
  import {
    useSpotifyPlayer,
    SPOTIFY_EVENT,
  } from "~/shared/hooks/spotify.svelte";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();

  const session = $derived.by(getGameContext);

  useSpotifyPlayer({
    name: "Songy room",
    getOAuthToken: (cb) => {
      void session
        .getProvider()
        .then(({ token }) => {
          cb(token);
        })
        .catch(() => {});
    },
    on: {
      [SPOTIFY_EVENT.READY]: ({ device_id }: { device_id: string }) => {
        void session.updateProvider({ device_id }).catch(() => {});
      },
    },
  });
</script>

{@render children?.()}
