<script>
  import { getGameContext } from "~components/GameContext.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";
  import { TURN_PHASE } from "~shared/types/turn";

  const { state, channel } = $derived(getGameContext());
  const { user: currentPlayer } = $derived.by(getScopeContext);

  let isPlayback = $derived(state?.player?.is_playback ?? false);
  const turnPhase = $derived(state?.turn?.phase);
  const activePlayerId = $derived.by(() => {
    return state?.turn?.queue?.[state?.turn?.cursor];
  });

  const showReady = $derived.by(() => {
    return (
      turnPhase === TURN_PHASE.STEADY && activePlayerId === currentPlayer?.uuid
    );
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
    class="btn"
    aria-label={isPlayback ? "Pause track" : "Play track"}
    onclick={togglePlayback}
  >
    {#if isPlayback}
      <svg class="icon" fill="currentColor" viewBox="0 0 24 24">
        <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
      </svg>
    {:else}
      <svg class="icon" fill="currentColor" viewBox="0 0 24 24">
        <path d="M8 5v14l11-7z" />
      </svg>
    {/if}
  </button>

  {#if showReady}
    <button
      class="btn"
      aria-label="Mark as ready to submit guess"
      onclick={handleReady}
    >
      Ready
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
    gap: 1rem;
  }

  .icon {
    width: 1.5rem;
    height: 1.5rem;
  }
</style>
