import type { PageProps } from "@inertiajs/core";
import type { Decorator, StoryContext } from "@storybook/svelte-vite";
import InertiaPageDecorator from "./page_decorator.svelte";

export interface InertiaParameters {
  name?: string;
  url?: string;
  version?: string | null;
}

type InertiaStoryContext = Omit<StoryContext<PageProps>, "parameters"> & {
  parameters: StoryContext<PageProps>["parameters"] & {
    inertia?: InertiaParameters;
  };
};

export const withInertiaPage = ((Story, { parameters, args, component }: InertiaStoryContext) => {
  const inertia = parameters.inertia;

  if (!inertia || !component) {
    return Story();
  }

  return {
    Component: InertiaPageDecorator,
    props: {
      page: component,
      pageProps: args,
      name: inertia.name ?? "page",
      url: inertia.url ?? "/",
      version: inertia.version ?? "storybook",
    },
  };
}) satisfies Decorator<PageProps>;
