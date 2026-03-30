<script lang="ts">
  import { untrack } from "svelte";
  import Equalizer from "~components/equalizer.svelte";
  import { setGameContext } from "~/contexts/game";
  import { createGameSession } from "~/stores/game.svelte";
  import type { Snippet } from "svelte";

  interface Props {
    topic: string;
    children?: Snippet;
  }

  let { children, topic }: Props = $props();

  const initialTopic = untrack(() => topic);

  const session = createGameSession({
    topic: initialTopic,
  });

  setGameContext(session);

  $effect(() => {
    return () => {
      session.dispose();
    };
  });
</script>

{#if session.game}
  {@render children?.()}
{:else if session.connection === "error" && session.error}
  <div class="game-channel__error" role="alert">
    <p class="text-lg font-semibold">Room unavailable</p>
    <p class="opacity-70">
      {typeof session.error === "object" &&
      session.error &&
      "reason" in session.error
        ? `Reason: ${session.error.reason}`
        : "Failed to load game state."}
    </p>
    <a class="btn btn-primary mt-4" href="/">Back home</a>
  </div>
{:else}
  <div class="game-channel__loader">
    <Equalizer />
  </div>
{/if}

<style>
  .game-channel__loader {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100%;
  }

  .game-channel__error {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 100%;
    padding: 1.5rem;
    text-align: center;
    gap: 0.5rem;
  }
</style>
