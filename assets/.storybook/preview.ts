import type { RequestHandler } from "msw";
import { initialize, mswLoader } from "msw-storybook-addon";
import type { Preview } from "@storybook/svelte-vite";
import { withInertiaPage } from "./decorators/inertia/decorator";
import { socketHandlers } from "../tests/msw";
import "../css/app.css";
import "./preview.css";

const storybookUserToken = "storybook-user-token";
window.userToken ??= storybookUserToken;

initialize(
  {
    onUnhandledRequest: "bypass",
    quiet: true,
  },
  socketHandlers as unknown as RequestHandler[],
);

const preview = {
  parameters: {
    layout: "fullscreen",
  },
  loaders: [mswLoader],
  decorators: [withInertiaPage],
} satisfies Preview;

export default preview;
