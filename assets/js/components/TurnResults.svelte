<script lang="ts">
  import Participants from "~components/Participants.svelte";
  import ActiveTimeline from "~components/ActiveTimeline.svelte";
  import { PUSH_EVENT } from "~shared/types/channel";
  import { getGameContext } from "~components/GameChannel.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import { inertia } from "@inertiajs/svelte";
  import { GAME_STATUS } from "~shared/types/game";

  const { channel, game } = $derived.by(getGameContext);
  const { user } = $derived.by(getScopeContext);
  const status = $derived(game?.status);

  const activePlayerUuid = $derived(game?.queue?.[game?.cursor]);
  const isActivePlayer = $derived(activePlayerUuid === user?.uuid);
  const isOwner = $derived(game?.owner_id === user?.uuid);
  const canAdvanceTurn = $derived(isActivePlayer || isOwner);

  const handleNextTurn = () => {
    channel.push(PUSH_EVENT.NEXT_PHASE, {});
  };
</script>

<Participants />
<ActiveTimeline />
{#if status === GAME_STATUS.FINISHED}
  <form use:inertia={{ href: "/create", method: "post" }}>
    <button type="submit" class="btn">Play again</button>
  </form>
{:else if canAdvanceTurn}
  <button class="btn" onclick={handleNextTurn}>Next Turn</button>
{/if}
