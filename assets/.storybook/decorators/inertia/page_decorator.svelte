<script lang="ts">
  import type { Page, PageProps } from "@inertiajs/core";
  import { App as InertiaApp, router } from "@inertiajs/svelte";
  import type { ResolvedComponent } from "@inertiajs/svelte";
  import type { Component } from "svelte";

  interface Props {
    page: Component<any>;
    name?: string;
    pageProps: PageProps;
    url: string;
    version?: string | null;
  }

  const noopRouterInit: typeof router.init = () => {};

  let {
    page,
    name = "storybook-page",
    pageProps,
    url,
    version = "storybook",
  }: Props = $props();

  router.init = noopRouterInit;

  $effect(() => {
    window.history.replaceState({}, "", url);
  });

  const component = $derived.by(() => {
    return {
      default: page as unknown as ResolvedComponent["default"],
    };
  });

  const inertiaProps = $derived.by(() => {
    const resolvedComponent = component;

    return {
      initialPage: {
        component: name,
        props: pageProps,
        url,
        version,
        clearHistory: false,
        encryptHistory: false,
      } as Page,
      initialComponent: resolvedComponent,
      resolveComponent: async (componentName: string) => {
        if (componentName !== name) {
          throw new Error(`Unexpected component: ${componentName}`);
        }

        return resolvedComponent;
      },
    };
  });
</script>

<InertiaApp {...inertiaProps} />
