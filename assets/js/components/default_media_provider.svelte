<script lang="ts">
  import type { Snippet } from "svelte";
  import { getGameContext } from "~/contexts/game";

  interface Props {
    children?: Snippet;
  }

  let { children }: Props = $props();

  const session = getGameContext();
  const game = $derived($session.snapshot?.game ?? null);
  const permissions = $derived($session.snapshot?.permissions ?? null);

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
      void session.pausePlayback().catch(() => {});
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
