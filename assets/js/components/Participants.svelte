<script>
  import { slide } from "svelte/transition";
  import { getGameContext } from "~components/GameChannel.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import star from "~icons/star.svg?raw";

  const { game } = $derived.by(getGameContext);
  const { user } = $derived.by(getScopeContext);
</script>

{#if game.participants && game.participants.length > 0}
  <div class="participants-header">
    {#each game.participants as participant}
      <div
        in:slide={{ duration: 400, axis: "y" }}
        out:slide={{ duration: 400, axis: "y" }}
        class="participant-wrapper"
      >
        <div class="participant-avatar">
          <img
            src={participant.avatar_url}
            alt={participant.name}
            class="avatar"
          />
        </div>

        {#if user && participant.uuid === user.uuid}
          <div class="star-indicator" aria-label="Your avatar">
            {@html star}
          </div>
        {/if}

        {#if game?.scores && participant.uuid in game.scores}
          <div class="score-indicator">
            {game.scores[participant.uuid]}
          </div>
        {/if}

        <div class="participant-name">
          <span class="name-text">
            {participant.name}
          </span>
        </div>
      </div>
    {/each}
  </div>
{/if}

<style>
  .participants-header {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 1rem;
    padding: 1rem;
    background: linear-gradient(to bottom, rgba(0, 0, 0, 0.2), transparent);
    backdrop-filter: blur(4px);
  }

  .participant-wrapper {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    transition: all 0.3s ease;
  }

  .participant-avatar {
    width: 6rem;
    height: 6rem;
    border-radius: 0.75rem;
    background: rgba(255, 255, 255, 0.2);
    backdrop-filter: blur(4px);
    overflow: hidden;
    border: 2px solid rgba(255, 255, 255, 0.3);
    box-shadow:
      0 10px 15px -3px rgba(0, 0, 0, 0.1),
      0 4px 6px -2px rgba(0, 0, 0, 0.05);
    transition: all 0.3s ease;
    padding: 0.25rem;
  }

  .participant-avatar:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: translateY(-0.25rem);
    box-shadow:
      0 20px 25px -5px rgba(0, 0, 0, 0.1),
      0 10px 10px -5px rgba(0, 0, 0, 0.04);
  }

  .avatar {
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 0.5rem;
  }

  .participant-name {
    margin-top: 0.5rem;
    text-align: center;
  }

  .name-text {
    font-size: 0.875rem;
    font-weight: 500;
    color: white;
    max-width: 6rem;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .star-indicator {
    position: absolute;
    top: -0.75rem;
    right: -0.75rem;
    width: 2rem;
    height: 2rem;
    z-index: 10;
    filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.3));
    pointer-events: none;
    transform: rotate(15deg);
  }

  .score-indicator {
    position: absolute;
    bottom: 1.25rem;
    right: -0.75rem;
    width: 2rem;
    height: 2rem;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
    border: 2px solid white;
    z-index: 10;
    pointer-events: none;
  }
</style>
