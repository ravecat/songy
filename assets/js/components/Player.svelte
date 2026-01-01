<script>
  import { getGameContext } from "~components/GameChannel.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";
  import { TURN_PHASE } from "~shared/types/turn";
  import { Play, Pause, SkipForward } from "lucide-svelte";

  const { game, channel } = $derived.by(getGameContext);
  const { user: currentPlayer } = $derived.by(getScopeContext);

  let isPlayback = $derived(game?.player?.is_playback ?? false);
  const turnPhase = $derived(game?.turn?.phase);
  const activePlayerId = $derived.by(() => {
    return game?.queue?.[game?.cursor];
  });

  const showReady = $derived.by(() => {
    const isActivePlayer = activePlayerId === currentPlayer?.uuid;

    // Show in READY phase if active player has made assumption
    if (turnPhase === TURN_PHASE.READY && isActivePlayer) {
      const hasAssumption = game?.turn?.assumptions?.some(
        (a) => a.user_id === currentPlayer?.uuid
      );
      return hasAssumption;
    }

    return false;
  });

  const togglePlayback = () => {
    channel.push(
      isPlayback ? PUSH_EVENT.PAUSE_PLAYBACK : PUSH_EVENT.START_PLAYBACK,
      {}
    );
  };

  const handleReady = () => {
    channel.push(PUSH_EVENT.NEXT_PHASE, {});
  };
</script>

<div class="panel">
  <button
    class="btn player-btn"
    aria-label={isPlayback ? "Pause track" : "Play track"}
    onclick={togglePlayback}
  >
    <span class="player-btn-icon">
      {#if isPlayback}
        <Pause />
      {:else}
        <Play />
      {/if}
    </span>
    <span class="player-btn-label">
      {isPlayback ? 'pause' : 'play'}
    </span>
  </button>

  {#if showReady}
    <button
      class="btn player-btn"
      aria-label="Next phase"
      onclick={handleReady}
    >
      <span class="player-btn-icon">
        <SkipForward />
      </span>
      <span class="player-btn-label">
        next
      </span>
    </button>
  {/if}
</div>

<style>
  .panel {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    padding: 1rem;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 2rem;
  }

  .player-btn {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 0.4rem;
    width: 5.5rem;
    height: 5.5rem;
  }

  .player-btn-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    color: currentColor;
    width: 3rem;
    height: 3rem;
  }

  .player-btn-icon :global(svg) {
    width: 100%;
    height: 100%;
  }

  .player-btn-label {
    font-size: 0.75rem;
    font-weight: 700;
    text-transform: lowercase;
    letter-spacing: 0.5px;
    line-height: 1;
  }
</style>
