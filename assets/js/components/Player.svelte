<script>
  import { getGameContext } from "~components/GameChannel.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";
  import { TURN_PHASE } from "~shared/types/turn";
  import { Play, Pause, SkipForward, RotateCcw } from "lucide-svelte";
  import { inertia } from "@inertiajs/svelte";
  import { slide } from "svelte/transition";
  import { cn } from "~shared/utils/cn";

  const { game, channel, permissions } = $derived.by(getGameContext);
  const isPlayback = $derived(game?.player?.is_playback);
  const turnPhase = $derived(game?.turn?.phase);

  const handlePlayback = () => {
    channel.push(
      isPlayback ? PUSH_EVENT.PAUSE_PLAYBACK : PUSH_EVENT.START_PLAYBACK,
      {}
    );
  };

  const handleStartGame = () => {
    channel.push(PUSH_EVENT.START_GAME, {});
  };

  const handleNextPhase = () => {
    channel.push(PUSH_EVENT.NEXT_PHASE, {});
  };
</script>

{#snippet button({ label, icon: Icon, text, visible = true, ...props })}
  {#if visible}
    <button
      in:slide={{ duration: 400 }}
      out:slide={{ x: 400, duration: 400 }}
      type={props.type ?? "button"}
      {...props}
      class={cn(
        "btn h-16 w-16 flex flex-col items-center justify-between py-2",
        props.class
      )}
      aria-label={label}
    >
      <span class="flex h-6 w-6 items-center justify-center text-current">
        <Icon />
      </span>
      <span class="text-xs font-bold uppercase tracking-wider leading-none">
        {text}
      </span>
    </button>
  {/if}
{/snippet}

{#snippet play()}
  {@render button({
    label: isPlayback ? "Pause track" : "Play track",
    icon: isPlayback ? Pause : Play,
    text: isPlayback ? "stop" : "play",
    onclick: handlePlayback,
    disabled: !(permissions?.can_control_playback ?? false),
  })}
{/snippet}

{#snippet start()}
  {@render button({
    label: "Ready",
    icon: SkipForward,
    text: "start",
    onclick: handleStartGame,
    class: "btn-primary",
    visible: permissions?.can_start_game ?? false,
  })}
{/snippet}

{#snippet ready()}
  {@render button({
    label: "Ready",
    icon: SkipForward,
    text: "ready",
    onclick: handleNextPhase,
    class: "btn-primary",
    visible: permissions?.can_ready,
  })}
{/snippet}

{#snippet forward()}
  {@render button({
    label: turnPhase === TURN_PHASE.READY ? "Next phase" : "Next turn",
    icon: SkipForward,
    text: turnPhase === TURN_PHASE.READY ? "forward" : "next turn",
    onclick: handleNextPhase,
    class: "btn-primary",
    visible:
      (permissions?.can_advance_turn ?? false) &&
      !(permissions?.can_start_game ?? false) &&
      !(permissions?.can_ready ?? false),
  })}
{/snippet}

{#snippet rewind()}
  <form use:inertia={{ href: "/create", method: "post" }} class="contents">
    {@render button({
      label: "Play again",
      icon: RotateCcw,
      text: "rewind",
      type: "submit",
      visible: permissions?.can_restart_game ?? false,
    })}
  </form>
{/snippet}

<div class="flex items-center justify-center gap-4 p-4">
  {@render rewind()}
  {@render play()}
  {@render start()}
  {@render ready()}
  {@render forward()}
</div>
