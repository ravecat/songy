<script lang="ts">
  import GameProvider from "~components/game_provider.svelte";
  import GameProviderContextProbe from "./game_provider_context_probe.svelte";

  interface Props {
    topic: string;
    onSession?: (session: unknown) => void;
  }

  let { topic, onSession }: Props = $props();
</script>

<GameProvider {topic}>
  <GameProviderContextProbe {onSession} />
</GameProvider>
