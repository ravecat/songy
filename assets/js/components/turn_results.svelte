<script lang="ts">
  import { getGameContext } from "~/contexts/game";
  import Sleeve from "~components/sleeve.svelte";

  const session = getGameContext();
  const game = $derived($session.snapshot?.game ?? null);
  const track = $derived(game?.track);

  const participants = $derived(game?.participants ?? {});
  const assumptions = $derived(game?.turn?.assumptions ?? {});

  const challengers = $derived(
    Object.values(assumptions)
      .map((userId) => participants[userId])
      .filter(Boolean),
  );

  const winnerId = $derived(game?.turn?.winner_id);
</script>

<div class="results">
  <div class="results__container">
    <div class="results__sleeve">
      <Sleeve {track} />
    </div>
  </div>
  <div class="results__avatars" role="list" aria-label="Result challengers">
    {#each challengers as user, i (user.id)}
      <div
        class="results__challenger"
        class:results__challenger--winner={user.id === winnerId}
        style="--index: {i}"
        role="listitem"
        aria-current={user.id === winnerId ? "true" : undefined}
      >
        <div class="results__frame">
          <img src={user.avatar_url} alt={user.name} class="results__avatar" />
          {#if user.id === winnerId}
            <span class="results__score"> +1 </span>
          {/if}
        </div>
        <span class="results__name">{user.name}</span>
      </div>
    {/each}
  </div>
</div>

<style>
  .results {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: var(--spacing-md);
    width: 100%;
    height: 100%;
  }

  .results__container {
    --record-sleeve-size: clamp(9.5rem, 56vw, 13.75rem);
    position: relative;
    inline-size: var(--record-sleeve-size);
    block-size: var(--record-sleeve-size);
    margin-inline: auto;
  }

  .results__sleeve {
    --sleeve-size: var(--record-sleeve-size);
    position: relative;
    z-index: var(--z-above);
    inline-size: var(--record-sleeve-size);
    block-size: var(--record-sleeve-size);
  }

  .results__avatars {
    display: flex;
    justify-content: center;
    align-items: flex-start;
    flex-wrap: wrap;
    max-inline-size: 100%;
    margin-top: var(--spacing-lg);
    gap: var(--spacing-md);
  }

  .results__challenger {
    display: flex;
    flex-direction: column;
    align-items: center;
    max-width: 5rem;
    animation: avatar-pop 0.4s var(--ease-bounce) backwards;
    animation-delay: calc(var(--index) * 0.08s + 0.2s);
  }

  .results__challenger:not(.results__challenger--winner) {
    opacity: var(--opacity-muted);
  }

  .results__frame {
    position: relative;
    padding: var(--spacing-xs);
    border: var(--border-thick) solid rgba(255, 255, 255, 0.8);
    border-radius: var(--radius-sm);
    box-shadow: var(--shadow-base);
  }

  .results__challenger--winner .results__frame {
    border-color: var(--color-gold);
    box-shadow: var(--shadow-gold-glow), var(--shadow-base);
  }

  .results__avatar {
    display: block;
    width: 4rem;
    height: 4rem;
    border-radius: var(--radius-sm);
    object-fit: cover;
  }

  .results__score {
    position: absolute;
    top: -0.625rem;
    right: -0.625rem;
    width: var(--spacing-md);
    height: var(--spacing-md);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: var(--font-size-xs);
    font-weight: var(--font-weight-bold);
    border-radius: var(--radius-sm);
    background: rgba(0, 0, 0, var(--opacity-muted));
    color: rgba(255, 255, 255, 0.9);
    animation: score-pop 0.3s var(--ease-bounce) backwards;
    animation-delay: calc(var(--index) * 0.08s + var(--delay-xl));
  }

  .results__challenger--winner .results__score {
    background: var(--gradient-gold);
    color: #000;
  }

  .results__name {
    width: 100%;
    margin-top: var(--spacing-sm);
    font-size: var(--font-size-xs);
    font-weight: var(--font-weight-medium);
    color: rgba(255, 255, 255, var(--opacity-emphasis));
    text-align: center;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  @keyframes avatar-pop {
    from {
      opacity: 0;
      transform: scale(0.5);
    }
  }

  @keyframes score-pop {
    from {
      opacity: 0;
      transform: scale(0);
    }
  }
</style>
