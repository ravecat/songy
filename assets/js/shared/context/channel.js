import { getContext } from "svelte";

export function getChannelContext() {
  const context = getContext("channel");

  if (!context) {
    throw new Error(
      "getChannelContext() must be called within a Channel component"
    );
  }

  return context;
}
