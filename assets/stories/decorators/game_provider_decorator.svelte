<script lang="ts">
  import type { Snippet } from "svelte";
  import {
    setGameContext,
    type GameContext,
  } from "~components/game_provider.svelte";
  import type { Game, Permissions } from "~contracts";

  interface Props {
    children?: Snippet;
    game: Game;
    permissions: Permissions;
  }

  let { children, game, permissions }: Props = $props();

  const context: GameContext = {
    get game() {
      return game;
    },
    get permissions() {
      return permissions;
    },
  };

  setGameContext(context);
</script>

{@render children?.()}
