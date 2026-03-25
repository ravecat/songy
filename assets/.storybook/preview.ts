import type { Preview } from "@storybook/svelte-vite";
import "../css/app.css";
import "./preview.css";

const preview: Preview = {
  parameters: {
    layout: "fullscreen",
  },
};

export default preview;
