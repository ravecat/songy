<script lang="ts">
  import { getGameContext } from "~components/game_provider.svelte";
  import { getScopeContext } from "~components/scope.svelte";
  import { Star } from "lucide-svelte";

  const { game } = $derived.by(getGameContext);
  const { user } = $derived.by(getScopeContext);

  const score = $derived.by(() => {
    if (!user?.uuid || !game?.scores) return 0;
    return game.scores[user.uuid] ?? 0;
  });
</script>

<button class="score-button" type="button" aria-label={`Your score: ${score}`}>
  <Star size={20} strokeWidth={2.5} />
  <span class="score-button__value">{score}</span>
</button>

<style>
  .score-button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.35rem;
    width: 3rem;
    height: 3rem;
    padding: 0.4rem;
    box-sizing: border-box;
    color: white;
    background: transparent;
    border: none;
    border-radius: var(--radius-md);
    cursor: pointer;
    padding: 0;
    transition: background-color 0.15s ease-out;
  }

  .score-button :global(svg) {
    flex-shrink: 0;
    display: block;
  }

  .score-button:hover {
    background-color: rgba(255, 255, 255, 0.1);
  }

  .score-button:active {
    background-color: rgba(255, 255, 255, 0.2);
  }

  .score-button:focus-visible {
    outline: var(--border-thick) solid rgba(255, 255, 255, 0.35);
    outline-offset: var(--spacing-xs);
  }

  .score-button__value {
    font-size: 1rem;
    font-weight: var(--font-weight-semibold);
    line-height: 1;
    min-width: 1.25rem;
  }
</style>
