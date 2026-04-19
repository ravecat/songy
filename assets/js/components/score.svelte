<script lang="ts">
  import { getGameContext } from "~/contexts/game";
  import { currentUser } from "~/stores/scope";

  const session = getGameContext();
  const game = $derived($session.snapshot?.game ?? null);

  const score = $derived.by(() => {
    if (!$currentUser?.id || !game?.scores) return 0;
    return game.scores[$currentUser.id] ?? 0;
  });
</script>

<div class="score-coin" role="img" aria-label={`Your score: ${score}`}>{score}</div>

<style>
  .score-coin {
    display: grid;
    place-items: center;
    width: 1.5rem;
    height: 1.5rem;
    box-sizing: border-box;
    border-radius: 9999px;
    background: var(--gradient-gold);
    box-shadow:
      0 0 0 1px var(--color-base-100),
      0 0 0 3px var(--color-primary);
    color: var(--spotify-black);
    font-size: 0.625rem;
    font-weight: 700;
    line-height: 1;
    font-variant-numeric: tabular-nums;
    text-align: center;
  }

  @media (width >= 640px) {
    .score-coin {
      width: 1.75rem;
      height: 1.75rem;
      font-size: 0.75rem;
    }
  }
</style>
