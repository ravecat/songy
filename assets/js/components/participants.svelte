<script lang="ts">
  import { getGameContext } from "~/contexts/game";
  import { Users } from "lucide-svelte";

  const session = getGameContext();
  const game = $derived($session.snapshot?.game ?? null);

  const playerCount = $derived(
    game?.participants ? Object.keys(game.participants).length : 0,
  );
</script>

<div
  class="participants-indicator"
  role="status"
  aria-live="polite"
  aria-atomic="true"
  aria-label={`${playerCount} player${playerCount !== 1 ? "s" : ""} online`}
>
  <Users size={20} strokeWidth={2.5} aria-hidden="true" />
  <span class="participants-indicator__value" aria-hidden="true">
    {playerCount}
  </span>
</div>

<style>
  .participants-indicator {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.35rem;
    width: 3rem;
    height: 3rem;
    padding: 0.4rem;
    box-sizing: border-box;
    background: transparent;
    border-radius: var(--radius-md);
    color: white;
    padding: 0;
  }

  .participants-indicator :global(svg) {
    flex-shrink: 0;
    display: block;
  }

  .participants-indicator__value {
    font-size: 1rem;
    font-weight: var(--font-weight-semibold);
    line-height: 1;
    min-width: 1.25rem;
  }
</style>
