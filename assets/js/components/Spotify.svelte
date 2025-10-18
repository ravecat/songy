<script lang="ts">
  import type { Snippet } from "svelte";
  import { getGameContext } from "~components/GameContext.svelte";
  import { useSpotifyPlayer, SPOTIFY_EVENT } from "~hooks/useSpotifyPlayer.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();

  const { channel } = $derived.by(getGameContext);

  useSpotifyPlayer({
    name: "Songy room",
    getOAuthToken: (cb) => {
      channel
        ?.push(PUSH_EVENT.GET_SPOTIFY_TOKEN, {})
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
