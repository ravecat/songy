import type { StorybookConfig } from "@storybook/svelte-vite";

const config: StorybookConfig = {
  stories: ["../stories/**/*.stories.@(ts|svelte)"],
  addons: ["@storybook/addon-svelte-csf", "@storybook/addon-vitest"],
  features: {
    sidebarOnboardingChecklist: false,
  },
  framework: "@storybook/svelte-vite",
};

export default config;
