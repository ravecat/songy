<script lang="ts">
  import { untrack } from "svelte";
  import Equalizer from "~components/equalizer.svelte";
  import { setGameContext } from "~/contexts/game";
  import { createGameSession } from "~/stores/game";
  import type { SessionError } from "~/transport/session";
  import type { Snippet } from "svelte";

  interface Props {
    topic: string;
    children?: Snippet;
  }

  let { children, topic }: Props = $props();

  const session = createGameSession(untrack(() => topic));

  function getErrorMessage(error: SessionError) {
    if (
      error.kind === "connect_error" &&
      typeof error.cause === "object" &&
      error.cause !== null &&
      "reason" in error.cause
    ) {
      return `Reason: ${String(error.cause.reason)}`;
    }

    return "Failed to load game state.";
  }

  setGameContext(session);
</script>

{#if $session.snapshot}
  {@render children?.()}
{:else if $session.status === "failed" && $session.error}
  <div class="game-channel__error" role="alert">
    <p class="text-lg font-semibold">Room unavailable</p>
    <p class="opacity-70">{getErrorMessage($session.error)}</p>
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
