<script lang="ts">
  import type { Snippet } from "svelte";
  import { getGameContext } from "~components/game_channel.svelte";
  import { PUSH_EVENT } from "~/shared/types/phoenix";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();

  const { game, permissions, channel } = $derived.by(getGameContext);

  const src = $derived.by(() => {
    const previewUrl = game?.track?.meta?.preview_url;
    if (typeof previewUrl === "string") {
      return previewUrl;
    }
  });
  const isPlayback = $derived(Boolean(game?.player?.is_playback));

  let audioElement = $state<HTMLAudioElement | null>(null);
  let loadedSrc = $state<string | null>(null);

  const loadSource = (nextSrc?: string) => {
    if (!audioElement) {
      return;
    }

    if (!nextSrc) {
      if (loadedSrc) {
        audioElement.pause();
        audioElement.removeAttribute("src");
        audioElement.load();
        loadedSrc = null;
      }
      return;
    }

    if (loadedSrc === nextSrc) {
      return;
    }

    audioElement.pause();
    audioElement.src = nextSrc;
    audioElement.load();
    audioElement.currentTime = 0;
    loadedSrc = nextSrc;
  };

  $effect(() => {
    loadSource(src);
  });

  $effect(() => {
    if (!audioElement) {
      return;
    }

    if (!src) {
      audioElement.pause();
      return;
    }

    if (isPlayback) {
      audioElement.play().catch(() => {});
    } else {
      audioElement.pause();
    }
  });

  const handleEnded = () => {
    if (!audioElement) {
      return;
    }

    audioElement.currentTime = 0;
    if (permissions?.can_control_playback) {
      channel.push(PUSH_EVENT.PAUSE_PLAYBACK, {});
    }
  };
</script>

<audio
  bind:this={audioElement}
  preload="auto"
  onended={handleEnded}
  style="display: none;"
></audio>

{@render children?.()}
