<script lang="ts">
  import { setContext } from "svelte";
  import type { Snippet } from "svelte";
  import { getChannelContext } from "~shared/context/channel";
  import { useSpotifyPlayer } from "~hooks/useSpotifyPlayer.svelte";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();

  const { channel } = $derived(getChannelContext());

  const player = useSpotifyPlayer({
    name: "Songy room",
    getOAuthToken: (cb: (token: string) => void) => {
      channel
        ?.push("get_spotify_token", {})
        .receive("ok", (payload: { token: string }) => {
          cb(payload.token);
        });
    },
    on: {
      ready: ({ device_id }: { device_id: string }) => {
        channel?.push("update_provider", { device_id });
      },
    },
  });

  setContext("spotify", player);
</script>

{@render children?.()}
