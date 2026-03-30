import { createContext } from "svelte";
import type {
  GameSession,
} from "~/stores/game.svelte";

export const [getGameContext, setGameContext] = createContext<GameSession>();
