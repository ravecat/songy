<script lang="ts">
  import type { StatePayload } from "~contracts";
  import { setGameContext } from "~/contexts/game";
  import type { GameCommandResult, GameSessionState } from "~/stores/game";

  interface SessionLike {
    snapshot?: StatePayload | null;
    status?: GameSessionState["status"];
    error?: GameSessionState["error"];
    commands?: Partial<{
      startGame: () => void;
      advanceTurn: () => Promise<GameCommandResult>;
      makeAssumption: (position: number) => Promise<GameCommandResult>;
      startPlayback: () => Promise<GameCommandResult>;
      pausePlayback: () => Promise<GameCommandResult>;
    }>;
  }

  interface Props {
    component: any;
    componentProps?: Record<string, unknown>;
    session?: SessionLike;
  }

  const noop = async (): Promise<GameCommandResult> => ({
    status: "ok",
    payload: undefined,
  });

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
      advanceTurn: () => (session.commands?.advanceTurn ?? noop)(),
      makeAssumption: (position) =>
        (session.commands?.makeAssumption ?? noop)(position),
      startPlayback: () => (session.commands?.startPlayback ?? noop)(),
      pausePlayback: () => (session.commands?.pausePlayback ?? noop)(),
    },
  });
</script>

<Component {...componentProps} />
