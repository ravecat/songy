import type { Preview } from "@storybook/svelte-vite";
import { game, permissions, users } from "../stories/mocks";
import "../css/app.css";

const preview: Preview = {
  parameters: {
    layout: "fullscreen",
  },
  loaders: [
    async () => ({
      game,
      permissions,
      user: users.alice,
    }),
  ],
};

export default preview;
