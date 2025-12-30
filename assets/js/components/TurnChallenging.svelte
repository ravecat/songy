<script lang="ts">
  import { getGameContext } from "~components/GameContext.svelte";
  import { getScopeContext } from "~components/Scope.svelte";
  import Participants from "~components/Participants.svelte";
  import Player from "~components/Player.svelte";
  import ActiveTimeline from "~components/ActiveTimeline.svelte";
  import CurrentTrack from "~components/CurrentTrack.svelte";

  const { state } = $derived.by(getGameContext);
  const { user: currentPlayer } = $derived.by(getScopeContext);

  const activePlayerId = $derived.by(() => {
    return state?.queue?.[state?.cursor];
  });
</script>

<Participants />
<ActiveTimeline />
<CurrentTrack />
<Player />
