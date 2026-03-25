<script lang="ts">
  import type { Socket } from "phoenix";
  import Equalizer from "~components/equalizer.svelte";
  import type { StatePayload } from "~contracts";
  import { type GameChannelSpec, setGameContext } from "~/contexts/game";
  import { untrack } from "svelte";
  import { useChannel } from "~/shared/hooks/channel.svelte";
  import type { Snippet } from "svelte";

  interface Props {
    socket: Socket;
    topic: string;
    children?: Snippet;
  }

  let { children, socket, topic }: Props = $props();

  let room = $state<StatePayload | null>(null);
  let error = $state<unknown>(null);

  function fail(err: unknown) {
    if (room) return;
    error = err;
  }

  const channel = useChannel<GameChannelSpec>({
    socket: untrack(() => socket),
    topic: untrack(() => topic),
    on: {
      state: (payload) => {
        room = payload;
      },
    },
    join: {
      ok: (payload) => {
        room = payload;
      },
      error: fail,
      timeout: () => fail(new Error("Connection timed out")),
    },
    onClose: () => fail(new Error("Connection closed unexpectedly")),
  });

  const context = {
    get game() {
      if (!room) throw new Error("Game is not ready");
      return room.game;
    },
    get permissions() {
      if (!room) throw new Error("Permissions not loaded");
      return room.permissions;
    },
    channel,
  };

  setGameContext(context);
</script>

{#if room}
  {@render children?.()}
{:else if error}
  <div class="game-channel__error" role="alert">
    <p class="text-lg font-semibold">Room unavailable</p>
    <p class="opacity-70">
      {typeof error === "object" && error && "reason" in error
        ? `Reason: ${error.reason}`
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
