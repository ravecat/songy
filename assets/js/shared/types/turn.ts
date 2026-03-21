import type { Turn } from "~contracts";

const turnPhases = [
  "waiting",
  "ready",
  "challenging",
  "results",
] as const satisfies readonly Turn["phase"][];

type AssertNever<T extends never> = T;
type _AllTurnPhasesCovered = AssertNever<
  Exclude<Turn["phase"], (typeof turnPhases)[number]>
>;

export const TURN_PHASE = {
  WAITING: turnPhases[0],
  READY: turnPhases[1],
  CHALLENGING: turnPhases[2],
  RESULTS: turnPhases[3],
} as const;

export type { Turn };
