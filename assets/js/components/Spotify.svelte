<script>
  import { setContext } from "svelte";
  import { getChannelContext } from "@shared/context/channel.js";
  import { useSpotifyPlayer } from "@hooks/useSpotifyPlayer.svelte.js";

  let { children } = $props();

  const channelContext = getChannelContext();
  let channel = $derived(channelContext.channel);

  const spotifyPlayer = useSpotifyPlayer({
    name: "Songy room",
    getOAuthToken: (cb) => {
      channel.push("get_spotify_token", {}).receive("ok", (payload) => {
        cb(payload.token);
      });
    },
    on: {
      ready: ({ device_id }) => {
        channel.push("update_provider", { device_id });
      },
    },
  });

  setContext("spotify-player", spotifyPlayer);
</script>

{@render children?.()}
