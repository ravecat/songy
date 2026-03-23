<script lang="ts" module>
  import { createContext } from "svelte";
  import type { Socket } from "phoenix";
  import type {
    AssumptionPayload,
    Game,
    JoinReply,
    Permissions,
    StatePayload,
    TimerPayload,
    UpdateProviderPayload,
    User,
  } from "~contracts";
  import type { Channel } from "~/shared/hooks/channel.svelte";

  interface GameProviderSpec {
    on: {
      state: StatePayload;
      timer: TimerPayload;
    };
    join: {
      ok: Extract<JoinReply, { status: "ok" }>["response"];
      error: Extract<JoinReply, { status: "error" }>["response"];
    };
    push: {
      start_game: {};
      advance_turn: {};
      make_assumption: { payload: AssumptionPayload };
      start_playback: {};
      pause_playback: {};
      update_provider: { payload: UpdateProviderPayload };
      get_provider: {
        reply: { ok: { token: string } };
      };
      get_current_user: {
        reply: { ok: User };
      };
    };
  }

  export interface GameContext {
    game: Game;
    permissions: Permissions;
    channel: Channel<GameProviderSpec>;
  }

  export const [getGameContext, setGameContext] = createContext<GameContext>();
</script>

<script lang="ts">
  import Equalizer from "~components/equalizer.svelte";
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

  const channel = useChannel<GameProviderSpec>({
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

  const context: GameContext = {
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
