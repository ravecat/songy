<script lang="ts">
  import type { StatePayload } from "~contracts";
  import { setGameContext } from "~/contexts/game";
  import type { createGameSession } from "~/stores/game";

  type GameSession = ReturnType<typeof createGameSession>;
  type GameSessionState =
    Parameters<GameSession["subscribe"]>[0] extends (value: infer TValue) => unknown
      ? TValue
      : never;

  interface SessionLike {
    snapshot?: StatePayload | null;
    status?: GameSessionState["status"];
    error?: GameSessionState["error"];
    startGame?: () => void;
    advanceTurn?: () => void;
    makeAssumption?: (position: number) => void;
    startPlayback?: () => void;
    pausePlayback?: () => void;
  }

  interface Props {
    component: any;
    componentProps?: Record<string, unknown>;
    session?: SessionLike;
  }

  let {
    component: Component,
    componentProps = {},
    session = {},
  }: Props = $props();

  function getState(): GameSessionState {
    return {
      snapshot: session.snapshot ?? null,
      status: session.status ?? (session.snapshot ? "ready" : "loading"),
      error: session.error ?? null,
    };
  }

  setGameContext({
    subscribe(run) {
      run(getState());
      return () => {};
    },
    startGame: () => (session.startGame ?? (() => {}))(),
    advanceTurn: () => (session.advanceTurn ?? (() => {}))(),
    makeAssumption: (position) => (session.makeAssumption ?? (() => {}))(position),
    startPlayback: () => (session.startPlayback ?? (() => {}))(),
    pausePlayback: () => (session.pausePlayback ?? (() => {}))(),
  });
</script>

<Component {...componentProps} />
