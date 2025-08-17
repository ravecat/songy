<script lang="ts">
  import { setContext } from "svelte";
  import type { Snippet } from "svelte";
  import { getGameContext } from "~components/GameContext.svelte";
  import { useSpotifyPlayer } from "~hooks/useSpotifyPlayer.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();

  const { channel } = $derived(getGameContext());

  const player = useSpotifyPlayer({
    name: "Songy room",
    getOAuthToken: (cb: (token: string) => void) => {
      channel
        ?.push(PUSH_EVENT.GET_SPOTIFY_TOKEN, {})
        .receive("ok", (payload: { token: string }) => {
          cb(payload.token);
        });
    },
    on: {
      ready: ({ device_id }: { device_id: string }) => {
        channel.push(PUSH_EVENT.UPDATE_PROVIDER, { device_id });
      },
    },
  });

  setContext("spotify", player);
</script>

{@render children?.()}
