<script lang="ts">
  import { getGameContext } from "~components/GameChannel.svelte";
  import Vinyl from "~components/Vinyl.svelte";
  import Sleeve from "~components/Sleeve.svelte";

  const { game } = $derived.by(getGameContext);
  const track = $derived(game?.track);

  const participants = $derived(
    new Map(game?.participants?.map((u) => [u.uuid, u]) ?? []),
  );

  const challengers = $derived(
    (game?.turn?.assumptions ?? []).map(
      ({ user_id }) => participants.get(user_id)!,
    ),
  );
</script>

<div class="results">
  <div class="results__container">
    <div class="results__vinyl">
      <Vinyl {track} />
    </div>
    <div class="results__sleeve">
      <Sleeve {track} />
    </div>
  </div>
  <div class="results__avatars">
    {#each challengers as user, i (user.uuid)}
      <img
        src={user.avatar_url}
        alt={user.name}
        class="results__avatar"
        style="--index: {i}"
      />
    {/each}
  </div>
</div>

<style>
  .results {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 1.5rem;
    width: 100%;
    height: 100%;
  }

  .results__container {
    position: relative;
    display: flex;
    align-items: center;
  }

  .results__vinyl {
    position: absolute;
    left: 110px;
    width: 200px;
    height: 200px;
    z-index: var(--z-base);
  }

  .results__sleeve {
    position: relative;
    z-index: var(--z-above);
  }

  .results__avatars {
    display: flex;
    justify-content: center;
    align-items: center;
    margin-top: 1rem;
    gap: 0.5rem;
  }

  .results__avatar {
    width: 4rem;
    height: 4rem;
    border-radius: var(--radius-sm);
    object-fit: cover;
    outline: var(--border-thick) solid rgba(255, 255, 255, 0.8);
    outline-offset: var(--spacing-xs);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
    animation: avatar-pop var(--animation-base) var(--ease-bounce) backwards;
    animation-delay: calc(var(--index) * 0.08s + var(--delay-base));
  }

  @keyframes avatar-pop {
    from {
      opacity: var(--opacity-full);
      transform: scale(0.5);
    }
  }
</style>
