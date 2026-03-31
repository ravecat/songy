<script lang="ts">
  import { setGameContext } from "~/contexts/game";

  interface SessionLike {
    snapshot?: unknown;
    status?: string;
    error?: unknown;
    startGame?: () => Promise<void>;
    advanceTurn?: () => Promise<void>;
    makeAssumption?: (position: number) => Promise<void>;
    startPlayback?: () => Promise<void>;
    pausePlayback?: () => Promise<void>;
    dispose?: () => void;
  }

  interface Props {
    component: any;
    componentProps?: Record<string, unknown>;
    session?: SessionLike;
  }

  const noop = async () => {};

  let {
    component: Component,
    componentProps = {},
    session = {},
  }: Props = $props();

  function getState() {
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
    startGame: () => (session.startGame ?? noop)(),
    advanceTurn: () => (session.advanceTurn ?? noop)(),
    makeAssumption: (position) => (session.makeAssumption ?? noop)(position),
    startPlayback: () => (session.startPlayback ?? noop)(),
    pausePlayback: () => (session.pausePlayback ?? noop)(),
    dispose: () => (session.dispose ?? (() => {}))(),
  });
</script>

<Component {...componentProps} />
