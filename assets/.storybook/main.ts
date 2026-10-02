import type { StorybookConfig } from "@storybook/svelte-vite";

const config: StorybookConfig = {
  stories: ["../stories/**/*.stories.@(ts|svelte)"],
  staticDirs: ["../public"],
  // Visual tests use the fonts pinned by the flake without CDN requests.
  previewHead: (head) =>
    process.env.VITEST
      ? head
      : `${head}
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,400;9..40,600;9..40,700&amp;display=swap" rel="stylesheet" />`,
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
