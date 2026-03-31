import { createContext } from "svelte";
import type {
  GameSessionStore,
} from "~/stores/game";

export const [getGameContext, setGameContext] = createContext<GameSessionStore>();
