<script>
  import { getGameContext } from "~components/GameChannel.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";
  import { TURN_PHASE } from "~shared/types/turn";
  import { GAME_STATUS } from "~shared/types/game";
  import { Play, Pause, SkipForward, RotateCcw } from "lucide-svelte";
  import { inertia } from "@inertiajs/svelte";

  const { game, channel } = $derived.by(getGameContext);
  const { user: currentPlayer } = $derived.by(getScopeContext);
  const isPlayback = $derived(game?.player?.is_playback);
  const turnPhase = $derived(game?.turn?.phase);
  const gameStatus = $derived(game?.status);
  const activePlayerId = $derived(game?.queue?.[game?.cursor]);
  const isActivePlayer = $derived(activePlayerId === currentPlayer?.uuid);
  const isOwner = $derived(game?.owner_id === currentPlayer?.uuid);

  const showAdvanceTurn = $derived.by(() => {
    // READY phase: Only active player, after making assumption
    if (turnPhase === TURN_PHASE.READY && isActivePlayer) {
      const hasAssumption = game?.turn?.assumptions?.some(
        (a) => a.user_id === currentPlayer?.uuid
      );
      return hasAssumption;
    }

    // RESULTS phase: Active player OR owner (but not if game is finished)
    if (
      turnPhase === TURN_PHASE.RESULTS &&
      gameStatus !== GAME_STATUS.FINISHED
    ) {
      return isActivePlayer || isOwner;
    }

    return false;
  });

  const showPlayAgain = $derived(gameStatus === GAME_STATUS.FINISHED);

  const playbackLabel = $derived(isPlayback ? "pause" : "play");
  const playbackAriaLabel = $derived(isPlayback ? "Pause track" : "Play track");

  const advanceTurnLabel = $derived(
    turnPhase === TURN_PHASE.READY ? "next" : "next turn"
  );
  const advanceTurnAriaLabel = $derived(
    turnPhase === TURN_PHASE.READY ? "Next phase" : "Next turn"
  );

  const togglePlayback = () => {
    channel.push(
      isPlayback ? PUSH_EVENT.PAUSE_PLAYBACK : PUSH_EVENT.START_PLAYBACK,
      {}
    );
  };

  const handleAdvanceTurn = () => {
    channel.push(PUSH_EVENT.NEXT_PHASE, {});
  };
</script>

<div class="flex items-center justify-center gap-8 p-4">
  <!-- Playback button (always visible) -->
  <button
    type="button"
    class="btn h-24 w-24 flex flex-col items-center justify-center gap-1"
    aria-label={playbackAriaLabel}
    onclick={togglePlayback}
  >
    <span
      class="flex h-12 w-12 flex-shrink-0 items-center justify-center text-current"
    >
      {#if isPlayback}
        <Pause class="h-full w-full" />
      {:else}
        <Play class="h-full w-full" />
      {/if}
    </span>
    <span class="text-xs font-bold uppercase tracking-wider leading-none">
      {playbackLabel}
    </span>
  </button>

  <!-- Advance turn button (READY or RESULTS phase) -->
  {#if showAdvanceTurn}
    <button
      type="button"
      class="btn h-24 w-24 flex flex-col items-center justify-center gap-1"
      aria-label={advanceTurnAriaLabel}
      onclick={handleAdvanceTurn}
    >
      <span
        class="flex h-12 w-12 flex-shrink-0 items-center justify-center text-current"
      >
        <SkipForward class="h-full w-full" />
      </span>
      <span class="text-xs font-bold uppercase tracking-wider leading-none">
        {advanceTurnLabel}
      </span>
    </button>
  {/if}

  <!-- Play again button (game finished) -->
  {#if showPlayAgain}
    <form use:inertia={{ href: "/create", method: "post" }} class="contents">
      <button
        type="submit"
        class="btn h-24 w-24 flex flex-col items-center justify-center gap-1"
        aria-label="Play again"
      >
        <span
          class="flex h-12 w-12 flex-shrink-0 items-center justify-center text-current"
        >
          <RotateCcw class="h-full w-full" />
        </span>
        <span class="text-xs font-bold uppercase tracking-wider leading-none">
          play again
        </span>
      </button>
    </form>
  {/if}
</div>
