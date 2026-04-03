import { createContext } from "svelte";
import type {
  createGameSession,
} from "~/stores/game";

export const [getGameContext, setGameContext] = createContext<ReturnType<typeof createGameSession>>();
