<script lang="ts">
  import { getGameContext } from "~/contexts/game";

  interface Props {
    onSession?: (session: unknown) => void;
  }

  let { onSession }: Props = $props();
  const session = getGameContext();

  $effect(() => {
    onSession?.(session);
  });
</script>

<div data-testid="game-provider-child">game-provider-child</div>
