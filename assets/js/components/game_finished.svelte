<script lang="ts">
  import { Crown } from "lucide-svelte";
  import { getGameContext } from "~/contexts/game";

  const session = getGameContext();
  const game = $derived($session.snapshot?.game ?? null);
  const participants = $derived(game?.participants ?? {});
  const scores = $derived(game?.scores ?? {});
  const queue = $derived(game?.queue ?? []);

  const leaderboard = $derived.by(() => {
    const orderedIds = [...new Set([...queue, ...Object.keys(scores)])];

    return orderedIds
      .map((userId, order) => {
        const participant = participants[userId];

        return {
          userId,
          name: participant?.name ?? userId,
          avatarUrl: participant?.avatar_url ?? null,
          score: scores[userId] ?? 0,
          order,
        };
      })
      .sort((left, right) => {
        if (right.score !== left.score) {
          return right.score - left.score;
        }

        return left.order - right.order;
      });
  });

  const winner = $derived.by(() => {
    const value = leaderboard[0];

    if (!value) {
      throw new Error("Finished game requires a winner");
    }

    return value;
  });
</script>

<section class="game-finished" aria-label="Game finished">
  <div class="game-finished__hero">
    <span class="game-finished__eyebrow">Game over</span>
    <h2 class="game-finished__title">{winner.name} wins</h2>

    <div class="game-finished__winner-badge">
      {#if winner.avatarUrl}
        <img
          src={winner.avatarUrl}
          alt={winner.name}
          class="game-finished__winner-avatar"
        />
      {:else}
        <div class="game-finished__winner-fallback" aria-hidden="true">
          <Crown size={28} strokeWidth={2.25} />
        </div>
      {/if}
    </div>
  </div>

  <ol class="game-finished__leaderboard" aria-label="Final leaderboard">
    {#each leaderboard as entry, index (entry.userId)}
      <li
        class="game-finished__entry"
        class:game-finished__entry--winner={index === 0}
        aria-current={index === 0 ? "true" : undefined}
      >
        <div class="game-finished__entry-rank">
          {#if index === 0}
            <Crown size={16} strokeWidth={2.25} />
          {:else}
            <span>{index + 1}</span>
          {/if}
        </div>

        <div class="game-finished__entry-user">
          {#if entry.avatarUrl}
            <img
              src={entry.avatarUrl}
              alt={entry.name}
              class="game-finished__entry-avatar"
            />
          {:else}
            <div
              class="game-finished__entry-avatar-fallback"
              aria-hidden="true"
            >
              {entry.name.slice(0, 1).toUpperCase()}
            </div>
          {/if}
          <span class="game-finished__entry-name">{entry.name}</span>
        </div>

        <span class="game-finished__entry-score">{entry.score}</span>
      </li>
    {/each}
  </ol>
</section>

<style>
  .game-finished {
    display: grid;
    align-content: start;
    justify-items: center;
    gap: clamp(0.875rem, 2.4vh, 1.5rem);
    box-sizing: border-box;
    padding: clamp(0.75rem, 2.4vmin, 1.5rem);
    width: 100%;
    min-height: 100%;
  }

  .game-finished__hero {
    display: grid;
    justify-items: center;
    gap: clamp(0.25rem, 1vh, 0.5rem);
    text-align: center;
  }

  .game-finished__eyebrow {
    font-size: 0.75rem;
    font-weight: var(--font-weight-semibold);
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: rgba(255, 255, 255, 0.65);
  }

  .game-finished__title {
    margin: 0;
    max-inline-size: min(12ch, 100%);
    font-size: clamp(1.75rem, 8vw, 3rem);
    line-height: 0.95;
    text-wrap: balance;
    color: var(--color-white);
  }

  .game-finished__winner-badge {
    display: flex;
    align-items: center;
    justify-content: center;
    width: clamp(4rem, 16vw, 5.5rem);
    height: clamp(4rem, 16vw, 5.5rem);
    padding: clamp(0.25rem, 1vw, 0.35rem);
    border-radius: 999px;
    background: linear-gradient(
      145deg,
      rgba(255, 255, 255, 0.16),
      rgba(255, 255, 255, 0.06)
    );
    border: 1px solid rgba(255, 255, 255, 0.18);
    box-shadow: var(--shadow-gold-glow), var(--shadow-base);
  }

  .game-finished__winner-avatar,
  .game-finished__winner-fallback {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
    border-radius: 999px;
    object-fit: cover;
    background: var(--gradient-gold);
    color: #111;
  }

  .game-finished__leaderboard {
    margin: 0;
    padding: 0;
    list-style: none;
    display: grid;
    align-content: start;
    width: min(100%, 32rem);
    gap: clamp(0.5rem, 1.2vh, 0.625rem);
  }

  .game-finished__entry {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr) auto;
    align-items: center;
    gap: clamp(0.625rem, 2vw, 0.75rem);
    padding: clamp(0.625rem, 1.4vh, 0.75rem) clamp(0.75rem, 2.5vw, 0.875rem);
    border-radius: var(--radius-md);
    background: rgba(255, 255, 255, 0.05);
    color: rgba(255, 255, 255, 0.82);
  }

  .game-finished__entry--winner {
    background: linear-gradient(
      135deg,
      rgba(242, 181, 0, 0.24),
      rgba(255, 255, 255, 0.08)
    );
    color: var(--color-white);
  }

  .game-finished__entry-rank {
    width: 1.5rem;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--color-gold);
    font-weight: var(--font-weight-bold);
  }

  .game-finished__entry-user {
    display: flex;
    align-items: center;
    gap: clamp(0.625rem, 2vw, 0.75rem);
    min-width: 0;
  }

  .game-finished__entry-avatar,
  .game-finished__entry-avatar-fallback {
    display: flex;
    align-items: center;
    justify-content: center;
    width: clamp(2.125rem, 8vw, 2.5rem);
    height: clamp(2.125rem, 8vw, 2.5rem);
    flex-shrink: 0;
    border-radius: 999px;
    object-fit: cover;
    background: rgba(255, 255, 255, 0.12);
    color: rgba(255, 255, 255, 0.9);
    font-weight: var(--font-weight-semibold);
  }

  .game-finished__entry-name {
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .game-finished__entry-score {
    min-width: 2ch;
    text-align: right;
    font-size: clamp(1rem, 3.6vw, 1.125rem);
    font-weight: var(--font-weight-bold);
    color: var(--color-gold);
  }
</style>
