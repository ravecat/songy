import type { Game } from "~contracts";

const gameStatuses = [
  "waiting",
  "in_progress",
  "finished",
] as const satisfies readonly Game["status"][];

export const GAME_STATUS = {
  WAITING: gameStatuses[0],
  IN_PROGRESS: gameStatuses[1],
  FINISHED: gameStatuses[2],
} as const;

export type { Game };
