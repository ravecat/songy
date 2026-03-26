<script lang="ts">
  import type { Snippet } from "svelte";
  import {
    setGameContext,
    type GameContext,
  } from "~/contexts/game";
  import type { Game, Permissions } from "~contracts";

  interface Props {
    children?: Snippet;
    game: Game;
    permissions: Permissions;
  }

  let { children, game, permissions }: Props = $props();

  const context: GameContext = {
    get state() {
      return { game, permissions };
    },
    get game() {
      return game;
    },
    get permissions() {
      return permissions;
    },
    timer: null,
    connection: "ready",
    error: null,
    startGame: () => Promise.resolve(),
    advanceTurn: () => Promise.resolve(),
    makeAssumption: () => Promise.resolve(),
    startPlayback: () => Promise.resolve(),
    pausePlayback: () => Promise.resolve(),
    updateProvider: () => Promise.resolve(),
    getProvider: () => Promise.resolve({ token: "" }),
  };

  setGameContext(context);
</script>

{@render children?.()}
