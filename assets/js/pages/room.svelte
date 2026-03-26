<script lang="ts">
  import Scope from "~components/scope.svelte";
  import socket from "~/socket";
  import GameProvider from "~components/game_provider.svelte";
  import Room from "~components/room.svelte";
  import MediaProvider from "~components/media_provider.svelte";
  import type { User } from "~contracts";

  interface ScopeProps {
    user: User;
    provider?: string;
  }

  interface Props {
    roomId: string;
    scope: ScopeProps;
  }

  let { roomId, scope }: Props = $props();
</script>

<GameProvider {socket} topic={`room:${roomId}`}>
  <MediaProvider provider={scope.provider}>
    <Scope currentUser={scope.user}>
      <Room />
    </Scope>
  </MediaProvider>
</GameProvider>
