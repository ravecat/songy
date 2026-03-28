import { createInertiaApp } from "@inertiajs/svelte";
import { render as svelteRender } from "svelte/server";

export function render(page) {
  return createInertiaApp({
    page,
    title: (title) => (title ? `${title} - Songy` : "Songy"),
    resolve: async (name) => {
      const pageModule = await import(`./pages/${name}.svelte`);
      return pageModule.default;
    },
    setup({ App, props }) {
      return svelteRender(App, { props });
    },
  });
}
