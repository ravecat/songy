<script lang="ts" module>
  import { createContext } from "svelte";
  import type { Channel } from "phoenix";
  import type { Game, Permissions } from "~contracts";

  export interface GameContext {
    game: Game;
    permissions: Permissions;
    channel: Channel;
  }

  export const [getGameContext, setGameContext] = createContext<GameContext>();
</script>

<script lang="ts">
  import Equalizer from "~components/equalizer.svelte";
  import { untrack } from "svelte";
  import { useChannel, type UseChannelOptions } from "~/shared/hooks/channel.svelte";
  import { BROADCAST_EVENT } from "~/shared/types/phoenix";
  import type { Snippet } from "svelte";
  import type { StatePayload } from "~contracts";

  interface Props {
    socket: UseChannelOptions["socket"];
    topic: UseChannelOptions["topic"];
    children?: Snippet;
    timeoutMs?: number;
  }

  let { children, timeoutMs = 6_000, socket, topic }: Props = $props();

  let game = $state<Game | null>(null);
  let permissions = $state<Permissions | null>(null);

  const { promise: ready, resolve, reject } = Promise.withResolvers<void>();

  const channel = useChannel({
    socket: untrack(() => socket),
    topic: untrack(() => topic),
    on: {
      [BROADCAST_EVENT.STATE]: (payload: StatePayload) => {
        game = payload.game;
        permissions = payload.permissions;
        resolve();
      },
    },
    join: {
      error: (r) => reject(r),
      timeout: () => reject(new Error("Connection timed out")),
    },
    onClose: () => reject(new Error("Connection closed unexpectedly")),
  });

  const stateTimeoutId = setTimeout(
    () => reject(new Error("Room took too long to respond")),
    untrack(() => timeoutMs),
  );

  $effect(() => {
    return () => {
      clearTimeout(stateTimeoutId);
      reject(new Error("Left the room"));
    };
  });

  const context: GameContext = {
    get game() {
      if (!game) throw new Error("Game is not ready");
      return game;
    },
    get permissions() {
      if (!permissions) throw new Error("Permissions not loaded");
      return permissions;
    },
    channel,
  };

  setGameContext(context);
</script>

<svelte:boundary>
  {await ready}
  {@render children?.()}

  {#snippet pending()}
    <div class="game-channel__loader">
      <Equalizer />
    </div>
  {/snippet}

  {#snippet failed(error)}
    <div class="game-channel__error" role="alert">
      <p class="text-lg font-semibold">Room unavailable</p>
      <p class="opacity-70">
        {typeof error === "object" && error && "reason" in error
          ? `Reason: ${error.reason}`
          : "Failed to load game state."}
      </p>
      <a class="btn btn-primary mt-4" href="/">Back home</a>
    </div>
  {/snippet}
</svelte:boundary>

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
