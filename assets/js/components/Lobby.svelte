<script>
  import { getGameContext } from "~components/GameContext.svelte";
  import Participants from "~components/Participants.svelte";
  import GameButton from "~components/GameButton.svelte";

  const { state } = $derived.by(getGameContext);
</script>

<Participants />
<GameButton />
