import type { StorybookConfig } from "@storybook/svelte-vite";

const config: StorybookConfig = {
  stories: ["../stories/**/*.stories.@(js|jsx|ts|tsx|svelte)"],
  addons: ["@storybook/addon-svelte-csf", "@storybook/addon-vitest"],
  features: {
    sidebarOnboardingChecklist: false,
  },
  framework: {
    name: "@storybook/svelte-vite",
    options: {},
  },
};

export default config;
