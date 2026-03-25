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

  const noopPush = {
    receive() {
      return noopPush;
    },
  };

  const context: GameContext = {
    get game() {
      return game;
    },
    get permissions() {
      return permissions;
    },
    channel: {
      on: () => 0,
      off: () => {},
      push: () => noopPush,
    } as unknown as GameContext["channel"],
  };

  setGameContext(context);
</script>

{@render children?.()}
