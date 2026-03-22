<script lang="ts">
  import type { Snippet } from "svelte";
  import { getGameContext } from "~components/game_channel.svelte";
  import {
    useSpotifyPlayer,
    SPOTIFY_EVENT,
  } from "~/shared/hooks/spotify.svelte";
  import { PUSH_EVENT } from "~/shared/types/phoenix";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();

  const { channel } = $derived.by(getGameContext);

  useSpotifyPlayer({
    name: "Songy room",
    getOAuthToken: (cb) => {
      channel
        .push(PUSH_EVENT.GET_PROVIDER, {})
        .receive("ok", ({ token }: { token: string }) => {
          cb(token);
        });
    },
    on: {
      [SPOTIFY_EVENT.READY]: ({ device_id }: { device_id: string }) => {
        channel.push(PUSH_EVENT.UPDATE_PROVIDER, { device_id });
      },
    },
  });
</script>

{@render children?.()}
