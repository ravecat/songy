import type { Page, PageProps } from "@inertiajs/core";
import { App as InertiaApp, router } from "@inertiajs/svelte";
import type { ResolvedComponent } from "@inertiajs/svelte";
import type { Component } from "svelte";
import { render as coreRender } from "vitest-browser-svelte";

interface RenderOptions<SharedProps extends PageProps = PageProps> {
  name?: string;
  props?: SharedProps;
  url?: string;
  version?: string | null;
}

const noopRouterInit: typeof router.init = () => {};

export function render<SharedProps extends PageProps = PageProps>(
  page: Component<any>,
  {
    name = "inertia-test-page",
    props = {} as SharedProps,
    url = "/",
    version = "test",
  }: RenderOptions<SharedProps> = {},
) {
  const component: ResolvedComponent = {
    default: page as unknown as ResolvedComponent["default"],
  };

  router.init = noopRouterInit;

  window.history.replaceState({}, "", url);

  return coreRender(InertiaApp, {
    props: {
      initialPage: {
        component: name,
        props,
        url,
        version,
        clearHistory: false,
        encryptHistory: false,
      } as Page<SharedProps>,
      initialComponent: component,
      resolveComponent: async (componentName) => {
        if (componentName !== name) {
          throw new Error(`Unexpected component: ${componentName}`);
        }

        return component;
      },
    },
  });
}
