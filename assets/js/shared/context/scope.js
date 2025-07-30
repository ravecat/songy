import { getContext } from "svelte";

export function getScopeContext() {
  const context = getContext("scope");

  if (!context) {
    throw new Error(
      "getScopeContext() must be called within a Scope component"
    );
  }

  return context;
}
