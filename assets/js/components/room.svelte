<script>
  import { getGameContext } from "~/contexts/game";
  import Game from "~components/game.svelte";
  import Equalizer from "~components/equalizer.svelte";
  import Player from "~components/player.svelte";
  import Participants from "~components/participants.svelte";
  import Score from "~components/score.svelte";
  import { currentUser } from "~/stores/scope";

  const session = getGameContext();
  const game = $derived($session.snapshot?.game ?? null);
  const currentParticipant = $derived.by(() => {
    if (!$currentUser) {
      return null;
    }

    return game?.participants?.[$currentUser.id] ?? $currentUser;
  });
</script>

<div class="room">
  {#if !game}
    <Equalizer />
  {:else}
    <main class="room__content">
      <div class="room__header">
        <div class="room__header-leading">
          {#if currentParticipant}
            <div class="room__player">
              <div class="room__player-avatar avatar">
                <div
                  class="ring-primary ring-offset-base-100 w-6 rounded-full ring-2 ring-offset-1 sm:w-7"
                >
                  <img
                    src={currentParticipant.avatar_url}
                    alt={currentParticipant.name}
                  />
                </div>
              </div>
              <span class="room__player-name">{currentParticipant.name}</span>
            </div>
          {/if}
        </div>
        <div class="room__header-actions">
          <Score />
          <Participants />
        </div>
      </div>
      <div class="room__body">
        <Game />
      </div>
      <Player />
    </main>
  {/if}
</div>

<style>
  .room {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .room__content {
    height: 100%;
    width: 100%;
    display: grid;
    grid-template-rows: auto minmax(0, 1fr) auto;
  }

  .room__body {
    min-height: 0;
    overflow-y: auto;
    overscroll-behavior: contain;
    scrollbar-width: none;
  }

  .room__body::-webkit-scrollbar {
    display: none;
  }

  .room__header {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
    min-width: 0;
  }

  .room__header-leading {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    flex: 1 1 auto;
    min-width: 0;
  }

  .room__player {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    min-width: 0;
    flex: 1 1 auto;
  }

  .room__player-avatar {
    flex: 0 0 auto;
  }

  .room__player-name {
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    color: var(--color-white);
    font-size: 0.9375rem;
    font-weight: var(--font-weight-semibold);
  }

  .room__header-actions {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    flex: 0 0 auto;
    gap: 0.75rem;
    min-width: 0;
    margin-left: auto;
  }
</style>
