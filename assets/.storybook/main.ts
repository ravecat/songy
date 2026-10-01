import type { StorybookConfig } from "@storybook/svelte-vite";

const config: StorybookConfig = {
  stories: ["../stories/**/*.stories.@(ts|svelte)"],
  staticDirs: ["../public"],
  addons: [
    "@storybook/addon-svelte-csf",
    "@storybook/addon-a11y",
    "@storybook/addon-vitest",
    "@storybook/addon-themes",
  ],
  core: {
    disableTelemetry: true,
    disableWhatsNewNotifications: true,
  },
  features: {
    sidebarOnboardingChecklist: false,
  },
  framework: "@storybook/svelte-vite",
};

export default config;
