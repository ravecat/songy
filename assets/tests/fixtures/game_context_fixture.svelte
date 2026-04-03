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
    commands?: Partial<{
      startGame: () => void;
      advanceTurn: () => void;
      makeAssumption: (payload: { position: number }) => void;
      startPlayback: () => void;
      pausePlayback: () => void;
    }>;
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
    commands: {
      startGame: () => (session.commands?.startGame ?? (() => {}))(),
      advanceTurn: () => (session.commands?.advanceTurn ?? (() => {}))(),
      makeAssumption: (payload) =>
        (session.commands?.makeAssumption ?? (() => {}))(payload),
      startPlayback: () => (session.commands?.startPlayback ?? (() => {}))(),
      pausePlayback: () => (session.commands?.pausePlayback ?? (() => {}))(),
    },
  });
</script>

<Component {...componentProps} />
