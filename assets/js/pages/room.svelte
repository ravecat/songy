<script lang="ts">
  import Scope from "~components/scope.svelte";
  import socket from "~/socket";
  import GameProvider from "~components/game_provider.svelte";
  import Room from "~components/room.svelte";
  import MediaProvider from "~components/media_provider.svelte";
  import QrContext from "~components/qr_context.svelte";
  import type { User } from "~contracts";

  interface ScopeProps {
    user: User;
    provider?: string;
  }

  interface Props {
    roomId: string;
    qrSvg: string;
    scope: ScopeProps;
  }

  let { roomId, qrSvg, scope }: Props = $props();
</script>

<GameProvider {socket} topic={`room:${roomId}`}>
  <MediaProvider provider={scope.provider}>
    <QrContext svg={qrSvg}>
      <Scope currentUser={scope.user}>
        <Room />
      </Scope>
    </QrContext>
  </MediaProvider>
</GameProvider>
