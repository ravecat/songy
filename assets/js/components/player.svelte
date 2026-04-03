<script lang="ts">
  import { getGameContext } from "~/contexts/game";
  import { Play, Pause, SkipForward, RotateCcw } from "lucide-svelte";
  import { inertia } from "@inertiajs/svelte";

  const session = getGameContext();
  const game = $derived($session.snapshot?.game ?? null);
  const permissions = $derived($session.snapshot?.permissions ?? null);
  const isPlayback = $derived(game?.player?.is_playback);

  const handlePlayback = () => {
    if (isPlayback) {
      session.commands.pausePlayback();
    } else {
      session.commands.startPlayback();
    }
  };

  const handleStartGame = () => {
    session.commands.startGame();
  };

  const handleAdvanceTurn = () => {
    session.commands.advanceTurn();
  };

  const rightBtn = $derived.by(() => {
    if (permissions?.can_start_game)
      return {
        label: "Start game",
        text: "start",
        handler: handleStartGame,
        enabled: true,
      };
    if (permissions?.can_start_turn)
      return {
        label: "Ready",
        text: "ready",
        handler: handleAdvanceTurn,
        enabled: true,
      };
    return {
      label: "Forward",
      text: "forward",
      handler: handleAdvanceTurn,
      enabled: permissions?.can_advance_turn,
    };
  });
</script>

<div class="player-strip" role="group" aria-label="Player controls">
  {#if permissions?.can_restart_game}
    <form use:inertia={{ href: "/create", method: "post" }} class="contents">
      <button type="submit" class="player-btn" aria-label="Play again">
        <RotateCcw class="h-5 w-5" />
        <span class="player-btn__label">rewind</span>
      </button>
    </form>
  {/if}
  <button
    type="button"
    class="player-btn player-btn--primary"
    aria-label={isPlayback ? "Pause track" : "Play track"}
    aria-pressed={isPlayback ?? false}
    onclick={handlePlayback}
    disabled={!permissions?.can_control_playback}
  >
    <span
      class="player-btn__indicator"
      class:player-btn__indicator--active={isPlayback}
      aria-hidden="true"
    ></span>
    {#if isPlayback}
      <Pause class="h-5 w-5" />
    {:else}
      <Play class="h-5 w-5" />
    {/if}
    <span class="player-btn__label">{isPlayback ? "stop" : "play"}</span>
  </button>
  <button
    type="button"
    class="player-btn"
    aria-label={rightBtn.label}
    onclick={rightBtn.handler}
    disabled={!rightBtn.enabled}
  >
    <SkipForward class="h-5 w-5" />
    <span class="player-btn__label">{rightBtn.text}</span>
  </button>
</div>

<style>
  .player-strip {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--spacing-sm);
    padding: var(--spacing-base) var(--spacing-md);
    padding-bottom: calc(var(--spacing-base) + env(safe-area-inset-bottom));
  }

  .player-btn {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: var(--spacing-sm);
    width: 4rem;
    height: 4rem;
    padding: var(--spacing-xs);
    background: radial-gradient(circle at 30% 30%, #4a4a4a, #1a1a1a);
    border: 1px solid #1a1a1a;
    border-radius: var(--radius-box);
    color: #d4d4d4;
    cursor: pointer;
    transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, 0.1),
      inset 0 -2px 4px rgba(0, 0, 0, 0.4),
      0 4px 8px rgba(0, 0, 0, 0.5);
  }

  .player-btn:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, 0.15),
      inset 0 -2px 4px rgba(0, 0, 0, 0.3),
      0 6px 12px rgba(0, 0, 0, 0.6);
  }

  .player-btn:active:not(:disabled) {
    transform: translateY(1px);
    box-shadow:
      inset 0 2px 4px rgba(0, 0, 0, 0.6),
      inset 0 -1px 0 rgba(255, 255, 255, 0.05),
      0 2px 4px rgba(0, 0, 0, 0.4);
  }

  .player-btn:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }

  .player-btn--primary {
    background: radial-gradient(circle at 30% 30%, #5a4a3a, #2a1a0a);
    border: 1px solid var(--color-orange);
    color: var(--color-orange);
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, 0.1),
      inset 0 -2px 4px rgba(0, 0, 0, 0.4),
      0 4px 8px rgba(0, 0, 0, 0.5);
  }

  .player-btn--primary:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, 0.15),
      inset 0 -2px 4px rgba(0, 0, 0, 0.3),
      0 6px 12px rgba(0, 0, 0, 0.6);
  }

  .player-btn--primary:active:not(:disabled) {
    box-shadow:
      inset 0 2px 4px rgba(0, 0, 0, 0.6),
      inset 0 -1px 0 rgba(255, 255, 255, 0.05),
      0 2px 4px rgba(0, 0, 0, 0.4);
  }

  .player-btn__label {
    font-size: 0.625rem;
    font-weight: var(--font-weight-semibold);
    text-transform: uppercase;
    letter-spacing: 0.1em;
    line-height: 1;
    font-family: "DM Sans", system-ui, sans-serif;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
  }

  .player-btn__indicator {
    position: absolute;
    top: 4px;
    right: 4px;
    width: 6px;
    height: 6px;
    border-radius: var(--radius-circle);
    background: color-mix(in srgb, var(--color-orange) 30%, transparent);
  }

  .player-btn__indicator--active {
    background: var(--color-orange);
    box-shadow: 0 0 8px color-mix(in srgb, var(--color-orange) 60%, transparent);
    animation: pulse var(--transition-slow) infinite;
  }

  @media (prefers-reduced-motion: reduce) {
    .player-btn {
      transition: none;
    }

    .player-btn:active:not(:disabled) {
      transform: none;
    }

    .player-btn__indicator--active {
      animation: none;
    }
  }
</style>
