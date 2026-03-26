import type { Meta } from "@storybook/svelte-vite";

/*
 * Intentionally kept as a placeholder.
 *
 * The previous version tried to storybook the Room Inertia page by mocking
 * page-adjacent runtime through decorators and context injection. That gave us
 * convenient visual states, but it also coupled the story to internal page
 * composition details instead of the actual integration boundary.
 *
 * Before re-enabling real stories for this page, revisit the strategy:
 * - decide whether the target is the Room screen component or the Inertia page
 * - define where Inertia/page state should be mocked
 * - define how socket/channel session state should be injected or simulated
 * - avoid inventing a fake production seam only for Storybook
 *
 * Keep this file so the decision stays visible in the codebase.
 */

const meta = {
  title: "Pages/Room",
  parameters: {
    docs: {
      description: {
        component:
          "Placeholder only. Revisit the Storybook strategy for Inertia pages before re-enabling Room stories.",
      },
    },
  },
} satisfies Meta;

export default meta;
